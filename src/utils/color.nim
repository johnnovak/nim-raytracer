import math
import glm


proc sRGBToLinear*(v: float32): float32 =
   let a = 0.055
   if v <= 0.04045:
      result = v / 12.92
   else:
      result = pow((v+a) / (1+a), 2.4)

proc sRGBToLinear*(v: Vec3[float32]): Vec3[float32] =
  result = vec3(sRGBToLinear(v.r),
                sRGBToLinear(v.g),
                sRGBToLinear(v.b))

proc linearToSRGB*(v: float32): float32 =
   let a = 0.055
   if v <= 0.0031308:
      result = 12.92 * v
   else:
      result = (1+a) * pow(v, 1/2.4) - a

proc linearToSRGB*(v: Vec3[float32]): Vec3[float32] =
  result = vec3(linearToSRGB(v.r),
                linearToSRGB(v.g),
                linearToSRGB(v.b))

proc gammaToLinear*(v: float32, gamma: float32 = 2.2): float32 =
  result = pow(v, gamma)

proc gammaToLinear*(v: Vec3[float32], gamma: float32 = 2.2): Vec3[float32] =
  result = vec3(gammaToLinear(v.r),
                gammaToLinear(v.g),
                gammaToLinear(v.b))

proc linearToGamma*(v: float32, gamma: float32 = 2.2): float32 =
  result = pow(v, 1/gamma)

proc linearToGamma*(v: Vec3[float32], gamma: float32 = 2.2): Vec3[float32] =
  result = vec3(linearToGamma(v.r),
                linearToGamma(v.g),
                linearToGamma(v.b))

