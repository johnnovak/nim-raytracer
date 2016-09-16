import math, random, strutils, terminal, times
import glm

import ../utils/framebuf
import geom, shader, stats

export geom, framebuf, stats


type
  AntialiasKind* = enum
    akNone, akGrid, akJittered, akMultiJittered

  Antialias* = ref AntialiasObj
  AntialiasObj = object
    case kind*: AntialiasKind
    of akNone: discard
    of akGrid: gridSize*: Natural
    of akJittered: jgridSize*: Natural
    of akMultiJittered: n*: Natural

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

proc primaryRay(w, h, x, y: Natural, xoffs, yoffs: float, fov: float,
                cameraToWorld: Mat4x4[float]): Ray =
  let
    r = w / h
    f = tan(degToRad(fov) / 2)
    cx = ((2 * (float(x) + xoffs) * r) / float(w) - r) * f
    cy = (1 - 2 * (float(y) + yoffs) / float(h)) * f

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


proc calcPixelNoAA(scene: Scene, opts: Options, x, y: Natural,
                   stats: var Stats): Vec3[float] =

  var ray = primaryRay(opts.width, opts.height, x, y, xoffs = 0, yoffs = 0,
                       opts.fov, opts.cameraToWorld)
  inc stats.numPrimaryRays
  trace(ray, scene.objects, stats)
  result = shade(ray, opts.bgColor)


proc calcPixelGridAA(scene: Scene, opts: Options, x, y, size: Natural,
                     jitter: bool, stats: var Stats): Vec3[float] =

  let
    nSamples = size * size
    gridSize = 1.0 / float(size)

  var samples = newSeq[Vec3[float]](nSamples)

  for j in 0..<size:
    for i in 0..<size:
      var
        xoffs = float(i) * gridSize + gridSize * 0.5
        yoffs = float(j) * gridSize + gridSize * 0.5

      if jitter:
        xoffs += random(1.0) - 0.5
        yoffs += random(1.0) - 0.5

      var ray = primaryRay(opts.width, opts.height, x, y, xoffs, yoffs,
                           opts.fov, opts.cameraToWorld)

      inc stats.numPrimaryRays
      trace(ray, scene.objects, stats)
      samples[j * size + i] = shade(ray, opts.bgColor)

  var
    color = vec3(0.0)

  for i in 0..samples.high:
    color = color + samples[i]
result = color * (1 / float(nSamples))


proc calcPixelMultiJittered(scene: Scene, opts: Options, x, y, size: Natural,
                            stats: var Stats): Vec3[float] =

  result = color * (1 / float(nSamples))



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
    of akNone: color = calcPixelNoAA(scene, opts, x, y, stats)

    of akGrid: color = calcPixelGridAA(scene, opts, x, y,
                                       opts.antialias.gridSize,
                                       jitter = false, stats)

    of akJittered: color = calcPixelGridAA(scene, opts, x, y,
                                           opts.antialias.gridSize,
                                           jitter = true, stats)

    of akMultiJittered: color = calcPixelMultiJittered(scene, opts, x, y,
                                             opts.antialias.gridSize, stats)

    if step > 1:
      for i in x..<min(x+step, opts.width):
        for j in y..<min(y+step, opts.height):
          fb[i,j] = color
    else:
      fb[x,y] = color

  result = stats


proc initRenderer*() =
  randomize()
