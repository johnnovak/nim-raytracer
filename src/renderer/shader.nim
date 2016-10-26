import math
import glm

import light, material
import ../utils/mathutils


proc shadeFacingRatio*(m: Material, n, v: Vec4[float]): Vec3[float] =
  result = m.albedo * max(0, n.dot(v))


proc shadeDiffuse*(m: Material, si: ShadingInfo,
                   hitNormal: Vec4[float]): Vec3[float] =

  result = m.albedo / PI *
           si.lightIntensity *
           max(0, hitNormal.dot(si.lightDir * -1))


when isMainModule:
  let m = Material(albedo: vec3(1.0, 1.0, 1.0), reflection: 0.0)
  let si = ShadingInfo(
    lightDir: vec4(0.1, 0.2, 0.3, 0.4),
    lightIntensity: vec3(0.5, 0.6, 0.7),
    lightDistance: 10.0)
  
  var r = shadeDiffuse(m, si, vec4(1.0, 2.0, 3.0, 4.0))
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

