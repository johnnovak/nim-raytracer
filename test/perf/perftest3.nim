type Vec3 = object {.byref.}
  x, y, z: float

type Ray = object {.byref.}
  dir, orig: Vec3

proc vec3(x, y, z: float): Vec3 {.inline.} =
  Vec3(x: x, y: y, z: z)

proc `-`(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(a.x - b.x, a.y - b.y, a.z - b.z)

proc dot(a, b: Vec3): float {.inline.} =
  result = a.x * b.x + a.y * b.y + a.z * b.z

proc cross(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x)

include "raytriangle.nim"

include "test.nim"


