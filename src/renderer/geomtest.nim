import math
import glm

type
  Ray* = ref object
    orig*, dir*: Vec4[float]   # origin and normalized direction vector
    depth*: int                # ray depth (number of recursions)
    invDir*: Vec3[float]       # 1/dir
    sign*: array[3, int]

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


when isMainModule:
  let b = initAABB(vmin = vec4(1.0), vmax = vec4(1.0))
  let r = initRay(orig = vec4(1.0), dir = vec4(1.0))
  let t = b.intersect(r)
  echo t
