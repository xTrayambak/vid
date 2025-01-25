import std/[options, tables, hashes, sequtils]

type
  Moment* = uint

  Sym* = object
    name*: string
    index*: uint
    moment*: Moment
    lifetime*: Option[Lifetime]
    uses*: uint = 0

  Register* = enum
    rax = "rax"
    rbx = "rbx"
    rcx = "rcx"
    rdx = "rdx"
    rsi = "rsi"
    rdi = "rdi"
    rbp = "rbp"
    rsp = "rsp"

  Lifetime* = object
    first*: Moment
    last*: Option[Moment]

  Vertex* = object
    name*: string

    reg*: Option[Register]
    adjacent*: seq[ptr Vertex]
    unavailableRegs*: seq[Register]

  InterferenceGraph* = object
    regs*: Table[string, Vertex]

func hash*(lifetime: Lifetime): Hash =
  var hash: Hash
  
  hash = hash !& lifetime.first.hash

  if lifetime.last.isSome:
    hash = hash !& lifetime.last.hash

  hash

func hash*(sym: Sym): Hash =
  var hash: Hash
  hash = hash !& sym.name.hash
  hash = hash !& sym.index.hash

  hash

func nextReg*(vertex: var Vertex, reg: Register = default Register) =
  if vertex.unavailableRegs.len < 1:
    vertex.unavailableRegs.setLen(vertex.adjacent.len)
    for i in 0 ..< vertex.adjacent.len:
      vertex.unavailableRegs[i] = get(vertex.adjacent[i][].reg)
  
  if not vertex.unavailableRegs.contains(reg):
    vertex.reg = some(reg)
    return

  vertex.nextReg(cast[Register](cast[int](reg) + 1))

func `dec`*(sym: var Sym) =
  dec sym.uses

func `inc`*(sym: var Sym) =
  inc sym.uses

func intersectsWith*(a, b: Lifetime): bool =
  b.first < a.last.get() and b.last.get() > a.first

func isValidIn*(lifetime: Lifetime, moment: Moment): bool =
  if lifetime.last.isNone:
    return

  lifetime.first >= moment and lifetime.last.get() <= moment

func `$`*(lifetime: Lifetime): string =
  result &= '(' & $lifetime.first
  if lifetime.last.isSome:
    result &= ", " & $lifetime.last.get()

  result &= ')'

func connect*(a, b: var Vertex) =
  a.adjacent.add(b.addr)
  b.adjacent.add(a.addr)

func drawEdges*(graph: var InterferenceGraph, basedOn: seq[Sym]) =
  func check(syms: seq[Sym]) =
    func each(sym: Sym, otherSyms: seq[Sym]) =
      if otherSyms.len < 1:
        return

      let
        other = otherSyms[0]
        itselfSym = sym
      
        otherLifetime = other.lifetime
        symLifetime = itselfSym.lifetime

      assert symLifetime.isSome and otherLifetime.isSome

      let
        otherLife = get(otherLifetime)
        symLife = get(symLifetime)

      if symLife.intersectsWith(otherLife):
        var
          otherVertex = graph.regs[other.name]
          vertex = graph.regs[itselfSym.name]

        vertex.connect(otherVertex)
        graph.regs[itselfSym.name] = move(vertex)
        graph.regs[other.name] = move(otherVertex)

      each(sym, otherSyms[1 ..< otherSyms.len])

    if syms.len < 1:
      return

    let head = syms[0]
    each(head, syms[1 ..< syms.len])
    check(syms[1 ..< syms.len])

func assignRegisters*(graph: var InterferenceGraph) =
  var vertices = graph.regs

  for i, _ in vertices:
    var vertex = vertices[i]
    vertex.nextReg()
    vertices[i] = move(vertex)

  graph.regs = move(vertices)

func initInterferenceGraph*(syms: seq[Sym]): InterferenceGraph =
  var graph: InterferenceGraph
  
  assert len(syms.filterIt(it.lifetime.isNone)) == 0
  
  graph.drawEdges(syms)
  graph.assignRegisters()

  move(graph)

func sym*(name: string, index: uint): Sym =
  Sym(name: name, index: index)
