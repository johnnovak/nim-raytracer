import math


type Vec3* = object {.byref.}
  x, y, z: float32


proc vec3*(x, y, z: float32): Vec3 {.inline.} =
  Vec3(x: x, y: y, z: z)

proc `-`*(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(a.x - b.x, a.y - b.y, a.z - b.z)

proc `+`*(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(a.x + b.x, a.y + b.y, a.z + b.z)

proc `*`*(a: Vec3, s: float32): Vec3 {.inline.} =
  result = vec3(a.x * s, a.y * s, a.z * s)

proc `/`*(a: Vec3, s: float32): Vec3 {.inline.} =
  result = vec3(a.x / s, a.y / s, a.z / s)

proc dot*(a, b: Vec3): float32 {.inline.} =
  result = a.x * b.x + a.y * b.y + a.z * b.z

proc cross*(a, b: Vec3): Vec3 {.inline.} =
  result = vec3(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x)

proc length*(a: Vec3): float32 =
  result = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)

proc normalize(a: Vec3): Vec3 =
  let len = length(a)
  result = vec3(a.x / len, a.y / len, a.z / len)


type Mat4* = object {.byref.}
  m*: array[16, float32]

const MAT4_ID = Mat4(m: [1.0'f32, 0.0'f32, 0.0'f32, 0.0'f32,
                         0.0'f32, 1.0'f32, 0.0'f32, 0.0'f32,
                         0.0'f32, 0.0'f32, 1.0'f32, 0.0'f32,
                         0.0'f32, 0.0'f32, 0.0'f32, 1.0'f32])

proc `[]`(m: Mat4, r, c: int): float32 {.inline.} =
  m.m[r*4 + c]

proc `[]=`(m: var Mat4, r, c: int, v: float32) {.inline.} =
  m.m[r*4 + c] = v

proc `*`(a, b: Mat4): Mat4 =
  for i in 0..4:
    for j in 0..4:
      for k in 0..4:
        result[i,j] = result[i,j] + a[i,k] * b[k,j]

#proc translate(m: Mat4, v: Vec3): Mat4 =
#proc rotate(m: Mat4, v: Vec3): Mat4 =
#proc inverse(m: Mat4, v: Vec3): Mat4 =

proc mulVec(m: Mat4, v: Vec3): Vec3 =
  result = vec3(m[0,0] * v.x + m[0,1] * v.y + m[0,2] * v.z,
                m[1,0] * v.x + m[1,1] * v.y + m[1,2] * v.z,
                m[2,0] * v.x + m[2,1] * v.y + m[2,2] * v.z)

proc mulPoint(m: Mat4, v: Vec3): Vec3 =
  result = vec3(m[0,0] * v.x + m[0,1] * v.y + m[0,2] * v.z + m[0,3],
                m[1,0] * v.x + m[1,1] * v.y + m[1,2] * v.z + m[1,3],
                m[2,0] * v.x + m[2,1] * v.y + m[2,2] * v.z + m[2,3])


when isMainModule:
  let
    m = MAT4_ID
    v = vec3(2.0, 3.0, 4.0)

  let a = m.mulVec(v)


