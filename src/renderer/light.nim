import math
import glm

import geom
import ../utils/mathutils


type
  Light* = ref object of RootObj
    color*: Vec3[float]
    intensity*: float

  DistantLight* = ref object of Light
    dir*: Vec4[float]

  PointLight* = ref object of Light
    pos*: Vec4[float]

type
  ShadingInfo* = ref object
    lightDir*: Vec4[float]
    lightIntensity*: Vec3[float]
    lightDistance*: float

const
  DEFAULT_LIGHT_POS = point(0.0, 0.0, 0.0)
  DEFAULT_LIGHT_DIR = vec(0.0, 0.0, -1.0)


method `$`*(i: Light): string {.base.} = ""

method `$`*(i: DistantLight): string =
  result = "DistantLight(color=" & $i.color &
           ", intensity=" & $i.intensity &
           ", dir=" & $i.dir & ")"

method `$`*(i: PointLight): string =
  result = "PointLight(color=" & $i.color &
           ", intensity=" & $i.intensity &
           ", pos=" & $i.pos & ")"


proc `$`*(si: ShadingInfo): string =
  result = "ShadingInfo(lightDir=" & $si.lightDir &
           ", lightIntensity=" & $si.lightIntensity &
           ", lightDistance=" & $si.lightDistance & ")"


method getShadingInfo*(i: Light, p: Vec4[float]): ShadingInfo {.base.} =
  ShadingInfo()

method getShadingInfo*(i: DistantLight, p: Vec4[float]): ShadingInfo =
  result = ShadingInfo(
    lightDir: i.dir,
    lightIntensity: i.color * i.intensity,
    lightDistance: Inf
  )

method getShadingInfo*(i: PointLight, p: Vec4[float]): ShadingInfo =
  var lightDir = p - i.pos
  let r2 = lightDir.length2()
  lightDir = lightDir.normalize()

  result = ShadingInfo(
    lightDir: lightDir,
    lightIntensity: i.color * i.intensity / (4*PI * r2),
    lightDistance: sqrt(r2)
  )


# Tests

#when isMainModule:
#  var c2w = mat4(1.0).rotate(vec3(1.0, 0.0, 0.0), degToRad(-12.0))
#                     .translate(vec3(1.0, 4.0, -3.0))
#
#  let dl = newDistantLight(color = vec3(0.2, 0.3, 0.4), intensity = 0.7,
#                           lightToWorld = c2w)
#
#  echo dl
#
#
#  c2w = mat4(1.0).rotate(vec3(0.0, 0.0, 1.0), degToRad(90.0))
#                 .translate(vec3(1.0, 4.0, -3.0))
#
#  let pl = newPointLight(color = vec3(0.2, 0.3, 0.4), intensity = 0.7,
#                         lightToWorld = c2w)
#
#  echo pl
#
#  let v = vec4(0.0, 0.0, -1.0, 1.0)
#  let m = mat4(1.0).translate(vec3(0.4, 0.5, 0.3))
