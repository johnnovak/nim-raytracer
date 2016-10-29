import math, random
import glm

import ../utils/framebuf
import geom, light, material, scene, shader, sampling, stats

export framebuf, geom, light, material, scene, stats


type
  AntialiasKind* = enum
    akNone, akGrid, akJittered, akMultiJittered, akCorrelatedMultiJittered

  Antialias* = ref AntialiasObj
  AntialiasObj = object
    gridSize*: Natural
    case kind*: AntialiasKind
    of akNone: discard
    of akGrid: discard
    of akJittered: discard
    of akMultiJittered: discard
    of akCorrelatedMultiJittered: discard

  Options* = object
    width*, height*: Natural
    antialias*: Antialias
    bias*: float
    maxRayDepth*: int


proc castPrimaryRay(w, h: Natural, x, y, fov: float,
                    cameraToWorld: Mat4x4[float]): Ray =

  const DEFAULT_CAMERA_POS = point(0.0, 0.0, 0.0)

  let
    r = w / h
    f = tan(degToRad(fov) / 2)
    cx = ((2 * x * r) / w.float - r) * f
    cy = (1 - 2 * y / h.float) * f

  result = initRay(orig = cameraToWorld * DEFAULT_CAMERA_POS,
                   dir = cameraToWorld * vec(cx, cy, -1).normalize,
                   x = x, y = y)


proc trace(ray: Ray, objects: seq[Object], tNear: float,
           stats: var Stats): tuple[objHit: Object, tHit: float] =
  var
    tmin = tNear
    objmin: Object = nil

  for obj in objects:
    let rayO = initRay(orig = obj.geometry.worldToObject * ray.orig,
                       dir = obj.geometry.worldToObject * ray.dir)

    var tHit = intersect(obj.geometry, rayO)
    inc stats.numIntersectionTests

    if tHit >= 0 and tHit < tmin:
      tmin = tHit
      objmin = obj
      # need to propagate triangleHit back to the original ray
      ray.triangleHit = rayO.triangleHit
      inc stats.numIntersectionHits

  result = (objmin, tmin)


# TODO move scene & options to front
proc shade(ray: Ray, objHit: Object, tHit: float, scene: Scene, opts: Options,
           stats: var Stats): Vec3[float] =

  if objHit == nil:
    result = scene.bgColor
  else:
    let
      hitW = ray.orig + (ray.dir * tHit)
      hitO = objHit.geometry.worldToObject * hitW
      viewDir = ray.dir * -1

    # TODO
    var hitNormal: Vec4[float]
    if ray.triangleHit == nil:
      hitNormal = objHit.geometry.objectToWorld * objHit.geometry.normal(hitO)
    else:
      let norm = TriangleMesh(objHit.geometry).normals[ray.triangleHit.normalIdx[0]]
      hitNormal = objHit.geometry.objectToWorld * norm

    result = vec3(0.0)

    # Calculate contribution from each light
    for light in scene.lights:
      let
        si = light.getShadingInfo(hitW)
        lightDir = si.lightDir * -1

      var shadowRay = initRay(orig = hitW + hitNormal * opts.bias,
                              dir = lightDir)

      let (shadowHit, _) = trace(shadowRay, scene.objects,
                                 tNear = si.lightDistance, stats)
      if shadowHit == nil:
        result = result + shadeDiffuse(objHit.material, si, hitNormal)

    # Calculate reflections
    let reflection = objHit.material.reflection
    if reflection > 0.0 and ray.depth <= opts.maxRayDepth:
      let
        i = ray.dir
        n = hitNormal
        r = i - 2 * n.dot(i) * n

      var rayR = initRay(orig = hitW + r * opts.bias,
                         dir = r,
                         depth = ray.depth + 1)

      let (objHitR, tHitR) = trace(rayR, scene.objects, tNear = Inf, stats)

      var reflColor: Vec3[float]
      if objHitR != nil:
        reflColor = shade(rayR, objHitR, tHitR, scene, opts, stats)
      else:
        reflColor = scene.bgColor

      result = (1.0 - reflection) * result +
                      reflection  * reflColor

#    result = shadeFacingRatio(objHit.material, hitNormal, viewDir)


proc calcPixelNoSampling(scene: Scene, opts: Options, x, y: Natural,
                         stats: var Stats): Vec3[float] =

  var ray = castPrimaryRay(opts.width, opts.height, x.float, y.float,
                           scene.fov, scene.cameraToWorld)

  inc stats.numPrimaryRays
  let (objHit, tHit) = trace(ray, scene.objects, tNear = Inf, stats)

  result = shade(ray, objHit, tHit, scene, opts, stats)


proc calcPixel(scene: Scene, opts: Options, x, y: Natural,
               samples: seq[Vec2[float]], stats: var Stats): Vec3[float] =

  result = vec3(0.0)

  for i in 0..samples.high:
    var ray = castPrimaryRay(opts.width, opts.height,
                             x.float + samples[i].x,
                             y.float + samples[i].y,
                             scene.fov, scene.cameraToWorld)

    inc stats.numPrimaryRays
    let (objHit, tHit) = trace(ray, scene.objects, tNear = Inf, stats)
    result = result + shade(ray, objHit, tHit, scene, opts, stats)

  result *= 1 / samples.len


proc renderLine*(scene: Scene, opts: Options,
                 fb: var Framebuf, y: Natural,
                 step: Natural = 1, maxStep: Natural =  1): Stats =

  assert isPowerOfTwo(step)
  assert isPowerOfTwo(maxStep)
  assert maxStep >= step

  var
    stats = Stats()
    color: Vec3[float]

  for x in countup(0, opts.width-1, step):
    if step < maxStep:
      let mask = step * 2 - 1
      if ((x and mask) == 0) and ((y and mask) == 0):
        continue

    case opts.antialias.kind:
    of akNone:
      color = calcPixelNoSampling(scene, opts, x, y, stats)

    of akGrid:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = grid(m, m), stats)

    of akJittered:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = jitteredGrid(m, m), stats)

    of akMultiJittered:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = multiJittered(m, m), stats)

    of akCorrelatedMultiJittered:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = correlatedMultiJittered(m, m), stats)

    if step > 1:
      for i in x..<min(x+step, opts.width):
        for j in y..<min(y+step, opts.height):
          fb[i,j] = color
    else:
      fb[x,y] = color

  result = stats


proc initRenderer*() =
  randomize()

