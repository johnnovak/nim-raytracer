import math
import glm

import ../utils/mathutils


template vec*[T](x, y, z: T): Vec4[T] = vec4(x, y, z, 0.0)
template point*[T](x, y, z: T): Vec4[T] = vec4(x, y, z, 1.0)


type
  # TODO change to ref when the thread GC bug is fixed
  Ray* = object
    pos*, dir*: Vec4[float]   # origin and normalized direction vector

proc `$`*(r: Ray): string =
  result = "Ray(pos=" & $r.pos & ", dir=" & $r.dir & ")"


type
  Geometry* = ref object of RootObj
    o*: Vec4[float]

  Sphere* = ref object of Geometry
    r*: float

  Plane* = ref object of Geometry
    n*: Vec4[float]


method `$`*(g: Geometry): string {.base.} = ""

method `$`*(s: Sphere): string =
  result = "Sphere(o=" & $s.o & ", r=" & $s.r & ")"

method `$`*(p: Plane): string =
  result = "Plane(o=" & $p.o & ", n=" & $p.n & ")"


method str*(g: Geometry): string {.base.} = ""

method str*(s: Sphere): string =
  result = "Sphere(o=" & $s.o & ", r=" & $s.r & ")"

method str*(p: Plane): string =
  result = "Plane(o=" & $p.o & ", n=" & $p.n & ")"


method intersect*(g: Geometry, r: Ray): float {.base.} = -Inf

method intersect*(s: Sphere, r: Ray): float =
  var
    a = r.dir.x * r.dir.x +
        r.dir.y * r.dir.y +
        r.dir.z * r.dir.z

    b = 2 * (r.dir.x * (r.pos.x - s.o.x) +
             r.dir.y * (r.pos.y - s.o.y) +
             r.dir.z * (r.pos.z - s.o.z))

    c = (s.o.x - r.pos.x) * (s.o.x - r.pos.x) +
        (s.o.y - r.pos.y) * (s.o.y - r.pos.y) +
        (s.o.z - r.pos.z) * (s.o.z - r.pos.z) - s.r * s.r

    delta = quadraticDelta(a, b, c)

  if delta >= 0.0:
    var (t1, t2) = solveQuadratic(a, b, c, delta)
    result = min(t1, t2)
  else:
    result = -Inf


method intersect*(p: Plane, r: Ray): float =
  var denom = p.n.dot(r.dir)
  if abs(denom) > 1e-6:
    var t = (p.o - r.pos).dot(p.n) / denom
    result = t
  else:
    result = -Inf


method normal*(g: Geometry, p: Vec4[float]): Vec4[float] {.base.} =
  vec4(0.0)

method normal*(s: Sphere, hit: Vec4[float]): Vec4[float] =
  result = (hit - s.o).normalize

method normal*(p: Plane, hit: Vec4[float]): Vec4[float] =
  result = p.n


# Tests

#TODO cleanup or remove
#when isMainModule:
#  var
#    s = Sphere(o: point(7.0, 9.0, -5.0),
#               albedo: vec3(0.0, 0.6, 0.2), r: 4.4)
#    r = Ray(o: point(7.0, 9.0, 0.0),
#            dir: vec(0.0, 0.0, -1.0))
#  echo r
#
#  var
#    p = Plane(o: point(1.0, 2.0, 3.0),
#              albedo: vec3(0.2, 0.75, 0.1),
#              n: vec(1.0, 0.0, 0.0))
#
#    intersects = s.intersect(r)
#
#  assert intersects == true
#  assert r.objHit == s
#  var objHit = r.objHit
#  echo objHit.str
#  assert eq(r.tHit, 0.6)
#
#  echo s
#  echo p
#  echo r

