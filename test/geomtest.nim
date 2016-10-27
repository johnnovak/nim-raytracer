# nim c --passC:-O2 --passC:-ffast-math -d:release geomtest

import math, times
import glm

#type Vec3[T] = array[3, T]
#
#proc vec3[T](x, y, z: T): Vec3[T] = Vec3[T]([x, y, z])
#
#proc x[T](v: Vec3[T]): T = v[0]
#proc y[T](v: Vec3[T]): T = v[1]
#proc z[T](v: Vec3[T]): T = v[2]
#

type
  Ray* = ref object
    orig*, dir*: Vec3[float]   # origin and normalized direction vector
    invDir*: Vec3[float]       # 1/dir
    sign*: array[3, int]

proc initRay*(orig, dir: Vec3[float]): Ray =
  let invDir = vec3(1/dir.x, 1/dir.y, 1/dir.z)
  let sign = [
    (invDir.x < 0).int,
    (invDir.y < 0).int,
    (invDir.z < 0).int,
  ]
  result = Ray(orig: orig, dir: dir, invDir: invDir, sign: sign)


type
  AABB* = ref object
    bounds*: array[2, Vec3[float]]

proc initAABB*(vmin, vmax: Vec3[float]): AABB =
  result = AABB(bounds: [vmin, vmax])


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


when isMainModule:
  let
    box = initAABB(vmin = vec3(-1.0, -1.0, -1.0), vmax = vec3(1.0, 1.0, 1.0))
    ray = initRay(orig = vec3(0.0, 0.0, 0.0), dir = vec3(0.1, 0.2, -0.8))

  var a = vec3(1.0, 2.0, 3.0)
  a[1] = 5.0
  echo $a
  echo $a[2]

  let tStart = epochTime()

  let N = 100_000_000
  var t = 0.0

  for i in 0..<N:
    t += intersect(box, ray)

  let tTotal = epochTime() - tStart

  echo "Total time: " & $tTotal & "s"
  echo "Millions of intersections per second: " & $(N.float / tTotal / 1_000_000)


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

