import math
import glm

import geom, light
import ../utils/mathutils


proc shadeFacingRatio*(obj: Object, n, v: Vec4[float]): Vec3[float] =
  result = obj.albedo * max(0, n.dot(v))


proc shadeDiffuse*(obj: Object, light: Light,
                   hitNormal, lightDir: Vec4[float]): Vec3[float] =

  result = obj.albedo / PI * light.intensity * light.color *
           max(0, hitNormal.dot(lightDir))


#method getShade*(p: Plane, r: Ray): Vec3[float] =
#  var
#    hit = r.o + (r.dir * r.tHit)
#    d = p.o - hit
#    scale = 0.1
#    cx = if modulo(d.x * scale) < 0.5: 0 else: 1
#    cz = if modulo(d.z * scale) < 0.5: 0 else: 1
#    patt = cx xor cz
#
#  result = p.albedo * float(patt)
#  var
#    hit = r.o + (r.dir * r.tHit)
#    n = s.normal(hit)
#    v = r.dir * -1
#    facingRatio = n.dot(v)
#
#  result = s.albedo * facingRatio

