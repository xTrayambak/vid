import std/[os, options, osproc]
import ./compiler/[ir, x86/codegen]

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
        strPoolRef: PoolRef(name: "consts", pos: 0'u)
      )
    ]
  )
)

var cgen: CodeGenerator
cgen.eat(program)
let asmSrc = cgen.emit()

echo asmSrc
writeFile("output.asm", asmSrc)
discard execCmd(assembler & " output.asm -o output.o")
discard execCmd("ld -o output output.o")
