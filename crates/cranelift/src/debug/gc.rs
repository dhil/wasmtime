use crate::debug::transform::AddressTransform;
use crate::debug::{Compilation, Reader};
use gimli::constants;
use gimli::read;
use gimli::UnitSectionOffset;
use std::collections::{HashMap, HashSet};
use wasmtime_environ::{PrimaryMap, StaticModuleIndex};

#[derive(Debug)]
pub struct Dependencies {
    edges: HashMap<UnitSectionOffset, HashSet<UnitSectionOffset>>,
    roots: HashSet<UnitSectionOffset>,
}

impl Dependencies {
    fn new() -> Dependencies {
        Dependencies {
            edges: HashMap::new(),
            roots: HashSet::new(),
        }
    }

    fn add_edge(&mut self, a: UnitSectionOffset, b: UnitSectionOffset) {
        use std::collections::hash_map::Entry;
        match self.edges.entry(a) {
            Entry::Occupied(mut o) => {
                o.get_mut().insert(b);
            }
            Entry::Vacant(v) => {
                let mut set = HashSet::new();
                set.insert(b);
                v.insert(set);
            }
        }
    }

    fn add_root(&mut self, root: UnitSectionOffset) {
        self.roots.insert(root);
    }

    pub fn get_reachable(&self) -> HashSet<UnitSectionOffset> {
        let mut reachable = self.roots.clone();
        let mut queue = Vec::new();
        for i in self.roots.iter() {
            if let Some(deps) = self.edges.get(i) {
                for j in deps {
                    if reachable.contains(j) {
                        continue;
                    }
                    reachable.insert(*j);
                    queue.push(*j);
                }
            }
        }
        while let Some(i) = queue.pop() {
            if let Some(deps) = self.edges.get(&i) {
                for j in deps {
                    if reachable.contains(j) {
                        continue;
                    }
                    reachable.insert(*j);
                    queue.push(*j);
                }
            }
        }
        reachable
    }
}

pub fn build_dependencies(
    compilation: &mut Compilation<'_>,
    dwp: &Option<read::DwarfPackage<Reader<'_>>>,
    at: &PrimaryMap<StaticModuleIndex, AddressTransform>,
) -> read::Result<Dependencies> {
    let mut deps = Dependencies::new();
    for (i, translation) in compilation.translations.iter() {
        let dwarf = &translation.debuginfo.dwarf;
        let mut units = dwarf.units();
        while let Some(unit) = units.next()? {
            build_unit_dependencies(unit, dwarf, dwp, &at[i], &mut deps)?;
        }
    }
    Ok(deps)
}

fn build_unit_dependencies(
    header: read::UnitHeader<Reader<'_>>,
    dwarf: &read::Dwarf<Reader<'_>>,
    dwp: &Option<read::DwarfPackage<Reader<'_>>>,
    at: &AddressTransform,
    deps: &mut Dependencies,
) -> read::Result<()> {
    let unit = dwarf.unit(header)?;
    let mut tree = unit.entries_tree(None)?;
    let root = tree.root()?;
    build_die_dependencies(root, dwarf, &unit, at, deps)?;

    if let Some(dwarf_package) = dwp {
        if let Some(dwo_id) = unit.dwo_id {
            if let Some(cu) = dwarf_package.find_cu(dwo_id, dwarf)? {
                if let Some(unit_header) = cu.debug_info.units().next()? {
                    build_unit_dependencies(unit_header, &cu, &None, at, deps)?;
                }
            }
        }
    }

    Ok(())
}

fn has_die_back_edge(die: &read::DebuggingInformationEntry<Reader<'_>>) -> bool {
    match die.tag() {
        constants::DW_TAG_variable
        | constants::DW_TAG_constant
        | constants::DW_TAG_inlined_subroutine
        | constants::DW_TAG_lexical_block
        | constants::DW_TAG_label
        | constants::DW_TAG_with_stmt
        | constants::DW_TAG_try_block
        | constants::DW_TAG_catch_block
        | constants::DW_TAG_template_type_parameter
        | constants::DW_TAG_enumerator
        | constants::DW_TAG_member
        | constants::DW_TAG_variant_part
        | constants::DW_TAG_variant
        | constants::DW_TAG_formal_parameter => true,
        _ => false,
    }
}

fn has_valid_code_range(
    die: &read::DebuggingInformationEntry<Reader<'_>>,
    dwarf: &read::Dwarf<Reader<'_>>,
    unit: &read::Unit<Reader<'_>>,
    at: &AddressTransform,
) -> read::Result<bool> {
    match die.tag() {
        constants::DW_TAG_subprogram => {
            if let Some(ranges_attr) = die.attr_value(constants::DW_AT_ranges)? {
                let offset = match ranges_attr {
                    read::AttributeValue::RangeListsRef(val) => {
                        dwarf.ranges_offset_from_raw(unit, val)
                    }
                    read::AttributeValue::DebugRngListsIndex(index) => {
                        dwarf.ranges_offset(unit, index)?
                    }
                    _ => return Ok(false),
                };
                let mut has_valid_base = if let Some(read::AttributeValue::Addr(low_pc)) =
                    die.attr_value(constants::DW_AT_low_pc)?
                {
                    Some(at.can_translate_address(low_pc))
                } else {
                    None
                };
                let mut it = dwarf.ranges.raw_ranges(offset, unit.encoding())?;
                while let Some(range) = it.next()? {
                    // If at least one of the range addresses can be converted,
                    // declaring code range as valid.
                    match range {
                        read::RawRngListEntry::AddressOrOffsetPair { .. }
                            if has_valid_base.is_some() =>
                        {
                            if has_valid_base.unwrap() {
                                return Ok(true);
                            }
                        }
                        read::RawRngListEntry::StartEnd { begin, .. }
                        | read::RawRngListEntry::StartLength { begin, .. }
                        | read::RawRngListEntry::AddressOrOffsetPair { begin, .. } => {
                            if at.can_translate_address(begin) {
                                return Ok(true);
                            }
                        }
                        read::RawRngListEntry::StartxEndx { begin, .. }
                        | read::RawRngListEntry::StartxLength { begin, .. } => {
                            let addr = dwarf.address(unit, begin)?;
                            if at.can_translate_address(addr) {
                                return Ok(true);
                            }
                        }
                        read::RawRngListEntry::BaseAddress { addr } => {
                            has_valid_base = Some(at.can_translate_address(addr));
                        }
                        read::RawRngListEntry::BaseAddressx { addr } => {
                            let addr = dwarf.address(unit, addr)?;
                            has_valid_base = Some(at.can_translate_address(addr));
                        }
                        read::RawRngListEntry::OffsetPair { .. } => (),
                    }
                }
                return Ok(false);
            } else if let Some(low_pc) = die.attr_value(constants::DW_AT_low_pc)? {
                if let read::AttributeValue::Addr(a) = low_pc {
                    return Ok(at.can_translate_address(a));
                } else if let read::AttributeValue::DebugAddrIndex(i) = low_pc {
                    let a = dwarf.debug_addr.get_address(4, unit.addr_base, i)?;
                    return Ok(at.can_translate_address(a));
                }
            }
        }
        _ => (),
    }
    Ok(false)
}

fn build_die_dependencies(
    die: read::EntriesTreeNode<Reader<'_>>,
    dwarf: &read::Dwarf<Reader<'_>>,
    unit: &read::Unit<Reader<'_>>,
    at: &AddressTransform,
    deps: &mut Dependencies,
) -> read::Result<()> {
    let entry = die.entry();
    let offset = entry.offset().to_unit_section_offset(unit);
    let mut attrs = entry.attrs();
    while let Some(attr) = attrs.next()? {
        build_attr_dependencies(&attr, offset, dwarf, unit, at, deps)?;
    }

    let mut children = die.children();
    while let Some(child) = children.next()? {
        let child_entry = child.entry();
        let child_offset = child_entry.offset().to_unit_section_offset(unit);
        deps.add_edge(child_offset, offset);
        if has_die_back_edge(child_entry) {
            deps.add_edge(offset, child_offset);
        }
        if has_valid_code_range(child_entry, dwarf, unit, at)? {
            deps.add_root(child_offset);
        }
        build_die_dependencies(child, dwarf, unit, at, deps)?;
    }
    Ok(())
}

fn build_attr_dependencies(
    attr: &read::Attribute<Reader<'_>>,
    offset: UnitSectionOffset,
    _dwarf: &read::Dwarf<Reader<'_>>,
    unit: &read::Unit<Reader<'_>>,
    _at: &AddressTransform,
    deps: &mut Dependencies,
) -> read::Result<()> {
    match attr.value() {
        read::AttributeValue::UnitRef(val) => {
            let ref_offset = val.to_unit_section_offset(unit);
            deps.add_edge(offset, ref_offset);
        }
        read::AttributeValue::DebugInfoRef(val) => {
            let ref_offset = UnitSectionOffset::DebugInfoOffset(val);
            deps.add_edge(offset, ref_offset);
        }
        _ => (),
    }
    Ok(())
}
