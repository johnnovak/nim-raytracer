import math


type Vec3* = object {.byref.}
  x*, y*, z*: float32

type Ray* = object {.byref.}
  dir*, orig*: Vec3

template r*(v: Vec3): float32 = v.x
template g*(v: Vec3): float32 = v.y
template b*(v: Vec3): float32 = v.z

template s*(v: Vec3): float32 = v.x
template t*(v: Vec3): float32 = v.y
template p*(v: Vec3): float32 = v.z


proc vec3*(x, y, z: float32): Vec3 {.inline.} =
  Vec3(x: x, y: y, z: z)

proc `-`*(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(a.x - b.x, a.y - b.y, a.z - b.z)

proc dot*(a, b: Vec3): float32 {.inline.} =
  result = a.x * b.x + a.y * b.y + a.z * b.z

proc cross*(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x)

proc len*(v: Vec3): float32 {.inline.} =
  result = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)

