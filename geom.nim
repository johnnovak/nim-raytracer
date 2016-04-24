import math
import glm

import mathutils


type
  Object* = ref object of RootObj
    o*: Vec3[float]
    color*: Vec3[float32]

  Sphere* = ref object of Object
    r*: float

  Plane* = ref object of Object
    n*: Vec3[float]

type
  Ray* = object
    o*, dir*: Vec3[float]   # origin and normalized direction vector
    objHit*: Object         # object hit by the ray
    tHit*: float            # point t on the ray where it hit the object


method intersect*(o: Object, r: var Ray): bool {.base.} = false

method intersect*(s: Sphere, r: var Ray): bool =
  var
    a = r.dir.x * r.dir.x +
        r.dir.y * r.dir.y +
        r.dir.z * r.dir.z

    b = 2 * (r.dir.x * (r.o.x - s.o.x) +
             r.dir.y * (r.o.y - s.o.y) +
             r.dir.z * (r.o.z - s.o.z))

    c = (s.o.x - r.o.x) * (s.o.x - r.o.x) +
        (s.o.y - r.o.y) * (s.o.y - r.o.y) +
        (s.o.z - r.o.z) * (s.o.z - r.o.z) - s.r * s.r

    delta = quadraticDelta(a, b, c)

  if delta < 0.0:
    result = false
  else:
    var (t1, t2) = solveQuadratic(a, b, c, delta)
    r.tHit = min(t1, t2)
    r.objHit = s
    result = true


method intersect*(p: Plane, r: var Ray): bool =
  var denom = p.n.dot(r.dir)
  if abs(denom) > 1e-6:
    var t = (p.o - r.o).dot(p.n) / denom
    if t >= 0:
      r.objHit = p
      r.tHit = t
      result = true


method getShade*(o: Object, r: Ray): Vec3[float32] {.base.} =
  vec3[float32](0.0, 0.0, 0.0)

method getShade*(s: Sphere, r: Ray): Vec3[float32] =
  var
    hit = r.o + (r.dir * r.tHit)
    n = (s.o - hit).normalize
    atten = n.dot(r.dir)

  result = s.color * atten


method getShade*(p: Plane, r: Ray): Vec3[float32] =

  proc modulo(x: float): float = abs(x - floor(x))

  var
    hit = r.o + (r.dir * r.tHit)
    d = p.o - hit
    scale = 0.1
    cx: int = if modulo(d.x * scale) < 0.5: 0 else: 1
    cz: int = if modulo(d.z * scale) < 0.5: 0 else: 1
    patt = cx xor cz

  result = p.color * float32(patt)


# Tests

when isMainModule:
  var
    s = Sphere(o: vec3[float](7.0, 9.0, -5.0), r: 4.4)

    r = Ray(o: vec3[float](7.0, 9.0, 0.0),
            dir: vec3[float](0.0, 0.0, -1.0))

    intersects = s.intersect(r)

  assert intersects == true
  assert r.objHit == s
  assert eq(r.tHit, 0.6)

