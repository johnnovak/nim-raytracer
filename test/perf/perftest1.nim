import glm

type Ray = ref object
  dir, orig: Vec3[float]

include "raytriangle.nim"

include "test.nim"

