import math
import glm

proc eq*(a, b: float64, maxRelDiff: float64 = 1e-15): bool =
  abs(a - b) <= max(abs(a), abs(b)) * maxRelDiff

proc eq*(a, b: float32, maxRelDiff: float32 = 1e-7): bool =
  abs(a - b) <= max(abs(a), abs(b)) * maxRelDiff

proc sign*(x: float): float =
  if x > 0:
    result = 1
  elif x < 0:
    result = -1
  else:
    result = 0

proc modulo*(x: float): float = abs(x - floor(x))

proc quadraticDelta*(a, b, c: float): float =
  b*b - 4*a*c

proc solveQuadratic*(a, b, c, delta: float): (float, float) =
  var
    t1: float = (-b - sign(b) * sqrt(delta)) / 2*a
    t2: float = c / (a*t1)
  result = (t1, t2)


# Tests

when isMainModule:
  var
    x1, x2: float
    a = 1.0
    b = -1.786737601482363
    c = 2.054360090947453e-8

  var delta = quadraticDelta(a, b, c)
  (x1, x2) = solveQuadratic(a, b, c, delta)

  assert eq(x1, 1.786737589984535)
  assert eq(x2, 1.149782767465722e-08)

