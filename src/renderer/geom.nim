import math
import glm

import ../utils/mathutils


const X_AXIS* = vec3(1.0, 0.0, 0.0)
const Y_AXIS* = vec3(0.0, 1.0, 0.0)
const Z_AXIS* = vec3(0.0, 0.0, 1.0)

template vec*[T](x, y, z: T): Vec4[T] = vec4(x, y, z, 0.0)
template vec*[T](v: Vec4[T]): Vec4[T] = vec4(v.xyz, 0.0)

template point*[T](x, y, z: T): Vec4[T] = vec4(x, y, z, 1.0)
template point*[T](v: Vec4[T]): Vec4[T] = vec4(v.xyz, 1.0)

template isVec*[T]  (v: Vec4[T]): bool = v.w == 0.0
template isPoint*[T](v: Vec4[T]): bool = v.w == 1.0


type
  Triangle* = ref object
    vertexIdx*: array[3, int]
    normalIdx*: array[3, int]

type
  Ray* = ref object
    orig*, dir*: Vec4[float]   # origin and normalized direction vector
    depth*: int                # ray depth (number of recursions)
    invDir*: Vec3[float]       # 1/dir
    sign*: array[3, int]
    triangleHit*: Triangle

proc initRay*(orig, dir: Vec4[float], depth: int = 1): Ray =
  let invDir = vec3(1/dir.x, 1/dir.y, 1/dir.z)
  let sign = [
    (invDir.x < 0).int,
    (invDir.y < 0).int,
    (invDir.z < 0).int,
  ]
  result = Ray(orig: orig, dir: dir, invDir: invDir, sign: sign)

proc `$`*(r: Ray): string =
  result = "Ray(orig=" & $r.orig & ", dir=" & $r.dir &
           ", invDir=" & $r.invDir & ")"


type
  AABB* = ref object
    vmin*, vmax*: Vec4[float]
    bounds*: array[2, Vec4[float]]

proc initAABB*(vmin, vmax: Vec4[float]): AABB =
  result = AABB(vmin: vmin, vmax: vmax, bounds: [vmin, vmax])

proc `$`*(b: AABB): string =
  result = "AABB(vmin=" & $b.vmin & ", vmax=" & $b.vmax & ")"

# From 'Robust BVH Ray Traversal', Thiago Ize, Solid Angle
# http://jcgt.org/published/0002/02/02/paper.pdf?
proc intersect*(b: AABB, r: Ray): float =
  var
    tmin = NegInf
    tmax = Inf
  let
    txmin = (b.bounds[  r.sign[0]].x - r.orig.x) * r.invDir.x
    txmax = (b.bounds[1-r.sign[0]].x - r.orig.x) * r.invDir.x
    tymin = (b.bounds[  r.sign[1]].y - r.orig.y) * r.invDir.y
    tymax = (b.bounds[1-r.sign[1]].y - r.orig.y) * r.invDir.y
    tzmin = (b.bounds[  r.sign[2]].z - r.orig.z) * r.invDir.z
    tzmax = (b.bounds[1-r.sign[2]].z - r.orig.z) * r.invDir.z

  tmin = max(tzmin, max(tymin, max(txmin, tmin)))
  tmax = min(tzmax, min(tymax, min(txmax, tmax)))
  # tmax * = 1.00000024f  # for float
  tmax *= 1.0000000000000004  # for double

  if tmin <= tmax:
    result = tmin
  else:
    result = NegInf

proc fastIntersect*(b: AABB, r: Ray): float =
  var tmin, tmax: float
  if r.invdir.x >= 0:
    tmin = (b.vmin.x - r.orig.x) * r.invdir.x
    tmax = (b.vmax.x - r.orig.x) * r.invdir.x
  else:
    tmin = (b.vmax.x - r.orig.x) * r.invdir.x
    tmax = (b.vmin.x - r.orig.x) * r.invdir.x

  var tymin, tymax: float
  if r.invdir.y >= 0:
    tymin = (b.vmin.y - r.orig.y) * r.invdir.y
    tymax = (b.vmax.y - r.orig.y) * r.invdir.y
  else:
    tymin = (b.vmax.y - r.orig.y) * r.invdir.y
    tymax = (b.vmin.y - r.orig.y) * r.invdir.y

  if (tmin > tymax) or (tymin > tmax): return NegInf

  if tymin > tmin: tmin = tymin
  if tymax < tmax: tmax = tymax

  var tzmin, tzmax: float
  if r.invdir.z >= 0:
    tzmin = (b.vmin.z - r.orig.z) * r.invdir.z
    tzmax = (b.vmax.z - r.orig.z) * r.invdir.z
  else:
    tzmin = (b.vmax.z - r.orig.z) * r.invdir.z
    tzmax = (b.vmin.z - r.orig.z) * r.invdir.z

  if tmin > tzmax or tzmin > tmax: return NegInf

  if tzmin > tmin: tmin = tzmin
  if tzmax < tmax: tmax = tzmax

  return tmin


type
  Geometry* = ref object of RootObj
    objectToWorld*: Mat4x4[float]
    worldToObject*: Mat4x4[float]

  Sphere* = ref object of Geometry
    r*: float

  Plane* = ref object of Geometry
    discard

  Box* = ref object of Geometry
    aabb*: AABB

  TriangleMesh* = ref object of Geometry
    vertices*: seq[Vec4[float]]
    normals*: seq[Vec4[float]]
    faces*: seq[Triangle]


proc initSphere*(r: float, objectToWorld: Mat4x4[float]): Sphere =
  result = Sphere(r: r,
                  objectToWorld: objectToWorld,
                  worldToObject: objectToWorld.inverse)


proc initPlane*(objectToWorld: Mat4x4[float]): Plane =
  result = Plane(objectToWorld: objectToWorld,
                 worldToObject: objectToWorld.inverse)

proc initBox*(vmin, vmax: Vec4[float], objectToWorld: Mat4x4[float]): Box =
  result = Box(aabb: initAABB(vmin = vmin, vmax = vmax),
               objectToWorld: objectToWorld,
               worldToObject: objectToWorld.inverse)


method `$`*(g: Geometry): string {.base.} = ""

method `$`*(s: Sphere): string =
  result = "Sphere(r=" & $s.r & ", objectToWorld: " & $s.objectToWorld & ")"

method `$`*(p: Plane): string =
  result = "Plane(objectToWorld: " & $p.objectToWorld & ")"

method `$`*(b: Box): string =
  result = "Box(aabb=" & $b.aabb &
           ", objectToWorld: " & $b.objectToWorld & ")"

method intersect*(g: Geometry, r: Ray): float {.base.} = NegInf

method intersect*(s: Sphere, r: Ray): float =
  var
    a = r.dir.x * r.dir.x +
        r.dir.y * r.dir.y +
        r.dir.z * r.dir.z

    b = 2 * (r.dir.x * r.orig.x +
             r.dir.y * r.orig.y +
             r.dir.z * r.orig.z)

    c = r.orig.x * r.orig.x +
        r.orig.y * r.orig.y +
        r.orig.z * r.orig.z - s.r * s.r

    delta = b*b - 4*a*c

  if delta >= 0.0:
    var
      t1: float = (-b - sign(b) * sqrt(delta)) / 2*a
      t2: float = c / (a*t1)
    result = min(t1, t2)
  else:
    result = NegInf


method intersect*(p: Plane, r: Ray): float =
  let n = vec(0.0, 1.0, 0.0)
  var denom = n.dot(r.dir)
  # TODO
  if abs(denom) > 1e-6:
    var t = -r.orig.dot(n) / denom
    result = t
  else:
    result = NegInf


method intersect*(b: Box, r: Ray): float =
  result = intersect(b.aabb, r)


proc rayTriangleIntersect(r: Ray, v0, v1, v2: Vec4[float]): float =
  let
    v0v1 = v1 - v0
    v0v2 = v2 - v0
    pvec = r.dir * v0v2
    det = v0v1.dot(pvec)

  if det < 0.0000001:
    return NegInf

  let
    invDet = 1 / det
    tvec = r.orig - v0
    u = tvec.dot(pvec) * invDet

  if u < 0 or u > 1:
    return NegInf

  let
    qvec = tvec * v0v1
    v = r.dir.dot(qvec) * invDet

  if v < 0 or u + v > 1:
    return NegInf

  result = v0v2.dot(qvec) * invDet


method intersect(m: TriangleMesh, r: Ray): float =
  var
    tMin = Inf

  for tri in m.faces:
    let
      v0 = m.vertices[tri.vertexIdx[0]]
      v1 = m.vertices[tri.vertexIdx[1]]
      v2 = m.vertices[tri.vertexIdx[2]]

      tHit = rayTriangleIntersect(r, v0, v1, v2)

    if tHit >= 0 and tHit < tMin:
      tMin = tHit
      r.triangleHit = tri

  result = tMin


method normal*(g: Geometry, p: Vec4[float]): Vec4[float] {.base.} =
  vec4(0.0)

method normal*(s: Sphere, hit: Vec4[float]): Vec4[float] =
  result = vec(hit).normalize

method normal*(p: Plane, hit: Vec4[float]): Vec4[float] =
  result = vec(0.0, 1.0, 0.0)

method normal*(b: Box, hit: Vec4[float]): Vec4[float] =
  let
    c = (b.aabb.vmin + b.aabb.vmax) * 0.5
    p = hit - c
    d = (b.aabb.vmin - b.aabb.vmax) * 0.5
    bias = 1.000001

  result = vec(((p.x / abs(d.x) * bias).int).float,
               ((p.y / abs(d.y) * bias).int).float,
               ((p.z / abs(d.z) * bias).int).float).normalize


# Tests

#TODO cleanup or remove
when isMainModule:
  var
    s = initSphere(r = 20, objectToWorld= mat4(1.0))

    r = initRay(orig = point(7.0, 9.0, 100.0),
                dir = vec(0.1, 0.2, -0.9))

  import times
  let tStart = epochTime()

  let N = 100_000_000
  var t = 0.0

  for i in 0..<N:
    t += intersect(s, r)

  let tTotal = epochTime() - tStart

  echo "Total time: " & $tTotal & "s"
  echo "Millions of intersections per second: " & $(N.float / tTotal / 1_000_000)

