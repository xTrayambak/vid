import std/[tables, terminal, os, options, osproc]
import ./compiler/[ir, x86/codegen]
import ./compiler/x86/register_allocator/types
import pretty

let
  ld = findExe("ld")
  assembler = findExe("as")

var program: Program
program.pools.add(
  Pool(
    name: "consts",
    data: @[
      Primitive(kind: pkString, strVal: "Hello Vid!")
    ]
  )
)
program.clauses.add(
  Clause(
    name: "main".some(),
    identifier: 0'u64,
    instructions: @[
      Instruction(
        op: LoadStrAddr,
        strSym: sym("msg", 0),
        strPoolRef: PoolRef(name: "consts", pos: 0'u)
      ),
      Instruction(
        op: LlPrint,
        printSym: sym("msg", 0)
      )
    ]
  )
)

var cgen: CodeGenerator
cgen.eat(program)

stdout.styledWriteLine("< ", styleBright, "CODEGEN", resetStyle, " >")
let asmSrc = cgen.emit()

echo asmSrc
writeFile("output.s", asmSrc)
stdout.styledWriteLine("< ", styleBright, "ASSEMBLE", resetStyle, " >")
discard execCmd(assembler & " output.s -o output.o")

stdout.styledWriteLine("< ", styleBright, "LINK", resetStyle, " >")
discard execCmd("ld -lc -o output output.o")

#[ var graph = initInterferenceGraph(
  @[
    Sym(
      name: "a",
      index: 0,
      moment: 0,
      lifetime: some(Lifetime(first: 0, last: some(3'u)))
    )
  ]
)
print graph ]#
