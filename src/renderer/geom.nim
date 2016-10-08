import math
import glm

import ../utils/mathutils


template vec*[T](x, y, z: T): Vec4[T] = vec4(x, y, z, 0.0)
template point*[T](x, y, z: T): Vec4[T] = vec4(x, y, z, 1.0)

template isVec*[T]  (v: Vec4[T]): bool = v.w == 0.0
template isPoint*[T](v: Vec4[T]): bool = v.w == 1.0


type
  Ray* = ref object
    pos*, dir*: Vec4[float]   # origin and normalized direction vector
    depth*: int               # ray depth (number of recursions)

proc `$`*(r: Ray): string =
  result = "Ray(pos=" & $r.pos & ", dir=" & $r.dir & ")"


type
  Geometry* = ref object of RootObj
    objectToWorld*: Mat4x4[float]
    worldToObject*: Mat4x4[float]

  Sphere* = ref object of Geometry
    r*: float

  Plane* = ref object of Geometry
    discard


proc initSphere*(r: float, objectToWorld: Mat4x4[float]): Sphere =
  # TODO cleanup
  var o2w = objectToWorld
  result = Sphere(r: r,
                  objectToWorld: objectToWorld,
                  worldToObject: o2w.inverse)


proc initPlane*(objectToWorld: Mat4x4[float]): Plane =
  # TODO cleanup
  var o2w = objectToWorld
  result = Plane(objectToWorld: objectToWorld,
                 worldToObject: o2w.inverse)


method `$`*(g: Geometry): string {.base.} = ""

method `$`*(s: Sphere): string =
  result = "Sphere(r=" & $s.r & ", objectToWorld: " & $s.objectToWorld & ")"

method `$`*(p: Plane): string =
  result = "Plane(objectToWorld: " & $p.objectToWorld & ")"


method intersect*(g: Geometry, r: Ray): float {.base.} = -Inf

method intersect*(s: Sphere, r: Ray): float =
  var
    a = r.dir.x * r.dir.x +
        r.dir.y * r.dir.y +
        r.dir.z * r.dir.z

    b = 2 * (r.dir.x * r.pos.x +
             r.dir.y * r.pos.y +
             r.dir.z * r.pos.z)

    c = r.pos.x * r.pos.x +
        r.pos.y * r.pos.y +
        r.pos.z * r.pos.z - s.r * s.r

    delta = quadraticDelta(a, b, c)

  if delta >= 0.0:
    var (t1, t2) = solveQuadratic(a, b, c, delta)
    result = min(t1, t2)
  else:
    result = -Inf


method intersect*(p: Plane, r: Ray): float =
  let n = vec(0.0, 1.0, 0.0)
  var denom = n.dot(r.dir)
  # TODO
  if abs(denom) > 1e-6:
    var t = -r.pos.dot(n) / denom
    result = t
  else:
    result = -Inf


method normal*(g: Geometry, p: Vec4[float]): Vec4[float] {.base.} =
  vec4(0.0)

method normal*(s: Sphere, hit: Vec4[float]): Vec4[float] =
  result = vec4(hit.xyz, 0).normalize

method normal*(p: Plane, hit: Vec4[float]): Vec4[float] =
  result = vec(0.0, 1.0, 0.0)


# Tests

#TODO cleanup or remove
when isMainModule:
  var m = mat4(1.0).translate(vec3(1.0, 2.0, 3.0))
  echo m
  echo m.inverse

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

