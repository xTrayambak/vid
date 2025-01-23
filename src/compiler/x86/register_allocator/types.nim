import std/options
import ../../ir

type
  Vertex* = object
    name*: string
    value*: Primitive

    reg*: Option[Register]
    adjacent*: seq[ref Vertex]
    unavailableRegs*: seq[Register]

func nextReg*(vertex: var Vertex, reg: Register) =
  if vertex.unavailableRegs.len < 1:
    vertex.unavailableRegs.setLen(vertex.adjacent.len)
    for i in 0 ..< vertex.adjacent.len:
      vertex.unavailableRegs[i] = get(vertex.adjacent[i][].reg)
  
  if not vertex.unavailableRegs.contains(reg):
    vertex.reg = some(reg)
    return

  vertex.nextReg(cast[Register](cast[int](reg) + 1))
