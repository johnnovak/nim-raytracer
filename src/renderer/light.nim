import math
import glm

import ../utils/mathutils


type
  Light* = ref object of RootObj
    color*: Vec3[float]
    intensity*: float

  DistantLight* = ref object of Light
    dir*: Vec4[float]


method `$`*(l: Light): string {.base.} = ""

method `$`*(l: DistantLight): string =
  result = "(DistantLight: color=" & $l.color &
           ", intensity=" & $l.intensity &
           ", dir=" & $l.dir & ")"

proc newDistantLight(color: Vec3[float], intensity: float,
                     lightToWorld: Mat4x4[float]): DistantLight =
  new(result)
  result.color = color
  result.intensity = intensity
  result.dir = (lightToWorld * vec4(0.0, 0.0, -1.0, 1.0)).normalize
  result.dir.w = 1.0


# Tests

when isMainModule:
  let c2w = mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                     .translate(vec3(1.0, 4.0, -3.0))

  let dl = newDistantLight(color = vec3(0.2, 0.3, 0.4), intensity = 0.7,
                           lightToWorld = c2w)


  let v = vec4(0.0, 0.0, -1.0, 1.0)
  let m = mat4(1.0).translate(vec3(0.4, 0.5, 0.3))

  # TODO
  # http://stackoverflow.com/questions/7574125/multiplying-a-matrix-and-a-vector-in-glm-opengl
  # GLM mimics GLSL, matrices column-major
  # column-major matrix should be left-multiplied with a vector
  # http://stackoverflow.com/questions/24593939/matrix-multiplication-with-vector-in-glsl
 
  echo dl

