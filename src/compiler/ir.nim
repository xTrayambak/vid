import std/options
import ./x86/register_allocator/types

type
  PrimitiveKind* = enum
    pkString
    
  Primitive* = object
    case kind*: PrimitiveKind
    of pkString:
      strVal*: string
  
  Pool* = object
    name*: string
    data*: seq[Primitive]

  PoolRef* = object
    name*: string
    pos*: uint

  Opcode* = enum
    LoadStrAddr = 0
    IntMul = 1
    LlPrint = 2
    ReturnVal = 3

  Instruction* = object
    case op*: Opcode
    of IntMul:
      mulA*, mulB*: Register
      mulDest*: Register
    of ReturnVal:
      retReg*: Register
    of LoadStrAddr:
      strPoolRef*: PoolRef
      lstrDest*: Register
      strSym*: Sym
    of LlPrint:
      printSym*: Sym

  Clause* = object
    identifier*: uint64
    name*: Option[string]
    instructions*: seq[Instruction]

  Program* = object
    pools*: seq[Pool] # Pools store pre-computed values the program needs
    clauses*: seq[Clause]

func toGASRegister*(register: Register): string =
  '%' & $register

func get*(clauses: seq[Clause], name: string): Clause =
  for cls in clauses:
    if cls.name.isNone:
      continue
    
    if cls.name.get() == name:
      return cls

  raise newException(ValueError, "No such clause exists: " & name)
