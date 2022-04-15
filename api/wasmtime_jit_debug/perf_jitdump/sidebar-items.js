initSidebarItems({"enum":[["RecordId","Defines jitdump record types"]],"struct":[["CodeLoadRecord","The CodeLoadRecord is used for describing jitted functions"],["DebugEntry","Describes source line information for a jitted function"],["DebugInfoRecord","Describes debug information for a jitted function. An array of debug entries are appended to this record during writting. Note, this record must preceed the code load record that describes the same jitted function."],["FileHeader","Fixed-sized header for each jitdump file"],["JitDumpFile","Interface for driving the creation of jitdump files"],["RecordHeader","Each record starts with this fixed size record header which describes the record that follows"]]});