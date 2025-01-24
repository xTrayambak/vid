import std/[strutils, tables]
import ../ir
import ./register_allocator/[types]
import pretty

type
  CodeGenerator* = object
    program*: Program
    output: string

    syms*: seq[Sym]
    tracker*: Table[Lifetime, Table[Sym, Register]]
    currLifetime*: Lifetime

template `>`*(data: string) =
  cgen.output &= data

template flush*() =
  cgen.output &= '\n'

template indent() =
  cgen.output &= '\t'

template dedent() =
  cgen.output &= '\n'

proc eat*(cgen: var CodeGenerator, program: sink Program) =
  cgen.program = move(program)

proc dataRef*(cgen: CodeGenerator, pool: Pool, num: uint): string =
  pool.name & '_' & $num

proc getPool*(cgen: CodeGenerator, name: string): Pool =
  for pool in cgen.program.pools:
    if pool.name == name:
      return pool

  raise newException(ValueError, "No such pool exists: " & name)

proc emit*(cgen: var CodeGenerator): string =
  # Generate data for pools
  indent
  > ".section .data"
  flush
  for pool in cgen.program.pools:
    for i, value in pool.data:
      let name = pool.name & '_' & $i
      > (name & ": ")
      flush
      indent
      case value.kind
      of pkString:
        > (".asciz \"" & value.strVal & '"')
      
      flush

  flush
  
  indent
  > ".section .text"
  flush; indent
  > ".global _start"
  flush; indent
  > ".extern printf"

  dedent

  > "_start:"
  flush; indent
  
  let clause = cgen.program.clauses.get("main")
  cgen.tracker[cgen.currLifetime] = initTable[Sym, Register]()
  for inst in clause.instructions:
    case inst.op
    of LoadStrAddr:
      > ("lea $1(%rip), %rdi" % [
          cgen.dataRef(
            cgen.getPool(inst.strPoolRef.name),
            inst.strPoolRef.pos
          )
        ]
      )
      cgen.syms &= inst.strSym
      cgen.tracker[cgen.currLifetime][inst.strSym] = rdi
    of Llprint:
      # low level print
      let sym = inst.printSym
      let reg = cgen.tracker[cgen.currLifetime][sym]
      flush; indent
      > "xor %eax, %eax"
      flush; indent
      > "call printf"
      flush; indent
    else: > "nop"

  flush; indent
  > "mov $60, %eax"
  flush; indent
  > "xor %edi, %edi"
  flush; indent
  > "syscall"
  dedent

  cgen.output
