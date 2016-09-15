import math
import glm

import geom
import ../utils/mathutils


method getShade*(o: Object, r: Ray): Vec3[float] {.base.} = vec3(0.0)

method getShade*(s: Sphere, r: Ray): Vec3[float] =
  var
    hit = r.o + (r.dir * r.tHit)
    n = (s.o - hit).normalize
    atten = n.dot(r.dir)

  result = s.albedo * atten


method getShade*(p: Plane, r: Ray): Vec3[float] =
  var
    hit = r.o + (r.dir * r.tHit)
    d = p.o - hit
    scale = 0.1
    cx = if modulo(d.x * scale) < 0.5: 0 else: 1
    cz = if modulo(d.z * scale) < 0.5: 0 else: 1
    patt = cx xor cz

  result = p.albedo * float(patt)

