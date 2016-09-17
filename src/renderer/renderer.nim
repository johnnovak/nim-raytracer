import math, random, strutils, terminal, times
import glm

import ../utils/framebuf
import geom, shader, sampling, stats

export geom, framebuf, stats


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

type
  Options* = object
    width*, height*: Natural
    fov*: float
    cameraToWorld*: Mat4x4[float]
    antialias*: Antialias
    bgColor*: Vec3[float]

type
  Scene* = object
    objects*: seq[Object]

const
  DEFAULT_CAMERA_POS = vec4(0.0, 0.0, 0.0, 1.0)


proc primaryRay(w, h: Natural, x, y, fov: float,
                cameraToWorld: Mat4x4[float]): Ray =
  let
    r = w / h
    f = tan(degToRad(fov) / 2)
    cx = ((2 * x * r) / w.float - r) * f
    cy = (1 - 2 * y / h.float) * f

  var o = cameraToWorld * DEFAULT_CAMERA_POS
  o.w = 1.0

  var dir = cameraToWorld * vec4(cx, cy, -1, 0).normalize
  dir.w = 0.0

  result = Ray(o: o, dir: dir)


proc trace(ray: var Ray, objects: seq[Object], stats: var Stats) =
  var
    tmin = Inf
    objmin: Object = nil

  for obj in objects:
    var hit = obj.intersect(ray)
    inc stats.numIntersectionTests

    if hit and ray.tHit < tmin:
      tmin = ray.tHit
      objmin = obj
      inc stats.numIntersectionHits

  ray.tHit = tmin
  ray.objHit = objmin


proc shade(ray: Ray, bgColor: Vec3[float]): Vec3[float] =
  if ray.objHit == nil:
    result = bgColor
  else:
    let o: Object = ray.objHit
    result = o.getShade(ray)


proc calcPixelNoSampling(scene: Scene, opts: Options, x, y: Natural,
                         stats: var Stats): Vec3[float] =

  var ray = primaryRay(opts.width, opts.height, x.float, y.float, opts.fov,
                       opts.cameraToWorld)

  inc stats.numPrimaryRays
  trace(ray, scene.objects, stats)
  result = shade(ray, opts.bgColor)


proc calcPixel(scene: Scene, opts: Options, x, y: Natural,
               samples: seq[Vec2[float]], stats: var Stats): Vec3[float] =

  result = vec3(0.0)

  for i in 0..samples.high:
    var ray = primaryRay(opts.width, opts.height,
                         x.float + samples[i].x,
                         y.float + samples[i].y,
                         opts.fov, opts.cameraToWorld)

    inc stats.numPrimaryRays
    trace(ray, scene.objects, stats)
    result = result + shade(ray, opts.bgColor)

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
