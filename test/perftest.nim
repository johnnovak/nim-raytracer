include times


type Vec3 = object {.byref.}
  x, y, z: float32

type Ray = ref object
  dir, orig: Vec3


proc vec(x, y, z: float32): Vec3 {.inline.} =
  Vec3(x: x, y: y, z: z)

proc `-`(a, b: Vec3): Vec3 {.inline.} =
  result = vec(a.x - b.x, a.y - b.y, a.z - b.z)

proc dot(a, b: Vec3): float32 {.inline.} =
  result = a.x * b.x + a.y * b.y + a.z * b.z

proc cross(a, b: Vec3): Vec3 {.inline.} =
  result = vec(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x)

proc calc(a, b: Vec3): float32 =
  let c1 = a.cross(b)
  let c2 = b.cross(a)
  let d = a.dot(b)
  result = c1.x + c2.y + c2.z + d


proc rayTriangleIntersect*(r: Ray, v0, v1, v2: Vec3): float =
  let
    v0v1 = v1 - v0
    v0v2 = v2 - v0
    pvec = r.dir.cross(v0v2)
    det = v0v1.dot(pvec)

  if det < 0.000001:
    return NegInf

  let
    invDet = 1 / det
    tvec = r.orig - v0
    u = tvec.dot(pvec) * invDet

  if u < 0 or u > 1:
    return NegInf

  let
    qvec = tvec.cross(v0v1)
    v = r.dir.dot(qvec) * invDet

  if v < 0 or u + v > 1:
    return NegInf

  result = v0v2.dot(qvec) * invDet


when isMainModule:
  let
    v1 = vec(-2.0, -1.0, -5.0)
    v2 = vec( 2.0, -1.0, -5.0)
    v3 = vec( 0.0,  1.0, -5.0)

  echo calc(v1, v2)

  let
    r = Ray(orig: vec(0.0, 0.0, 0.0), dir: vec(0.0, 0.0, -1.0))

  let tStart = epochTime()

  let N = 100_000_000
  var t = 0.0

  for i in 0..<N:
    t = rayTriangleIntersect(r, v1, v2, v3)

  let tTotal = epochTime() - tStart

  echo t

  echo "Total time: " & $tTotal & "s"
  echo "Millions of intersections per second: " & $(N.float / tTotal / 1_000_000)

