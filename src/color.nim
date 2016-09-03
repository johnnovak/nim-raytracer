import math


proc sRGBToLinear*(v: float32): float32 =
   let a = 0.055
   if v <= 0.04045:
      v / 12.92
   else:
      pow((v+a) / (1+a), 2.4)

proc linearToSRGB*(v: float32): float32 =
   let a = 0.055
   if v <= 0.0031308:
      12.92 * v
   else:
      (1+a) * pow(v, 1/2.4) - a

proc gammaToLinear*(v: float32, gamma: float32 = 2.2): float32 =
   pow(v, gamma)

proc linearToGamma*(v: float32, gamma: float32 = 2.2): float32 =
   pow(v, 1/gamma)

