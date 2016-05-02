import math, strutils, terminal, times
import glm
import framebuf, geom, shader, workerpool

export geom, framebuf, workerpool

type
  AntialiasKind* = enum
    akNone,
    akGrid

  Antialias* = ref AntialiasObj
  AntialiasObj = object
    case kind*: AntialiasKind
    of akNone: discard
    of akGrid: gridSize*: int

type
  Options* = object
    width*, height*: int
    fov*: float
    cameraToWorld*: Mat4x4[float]
    antialias*: Antialias
    bgColor*: Vec3[float]

type
  Scene* = object
    objects*: seq[Object]

type
  WorkMsg* = object
    scene*: ptr Scene
    opts*: Options
    framebuf*: ptr FramebufRef
    line*: int

type
  Stats* = object
    numPrimaryRays*: int
    numIntersectionTests*: int
    numIntersectionHits*: int

  ResponseMsg* = object
    stats*: Stats


proc `+=`*(l: var Stats, r: Stats) =
  l.numPrimaryRays += r.numPrimaryRays
  l.numIntersectionTests += r.numIntersectionTests
  l.numIntersectionHits += r.numIntersectionHits


const
  DEFAULT_CAMERA_POS = vec4(0.0, 0.0, 0.0, 1.0)

proc primaryRay(w, h, x, y: int, xoffs, yoffs: float, fov: float,
                cameraToWorld: Mat4x4[float]): Ray =
  let
    r = w / h
    f = tan(degToRad(fov) / 2)
    cx = ((2 * (float(x) + xoffs) * r) / float(w) - r) * f
    cy = (1 - 2 * (float(y) + yoffs) / float(h)) * f

  let
    o = cameraToWorld * DEFAULT_CAMERA_POS
    dir = cameraToWorld * vec4(cx, cy, -1, 0).normalize

  result = Ray(o: o.xyz, dir: dir.xyz)


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


proc calcPixelNoAA(scene: Scene, opts: Options, x, y: int,
                   stats: var Stats): Vec3[float] =

  var ray = primaryRay(opts.width, opts.height, x, y, xoffs = 0, yoffs = 0,
                       opts.fov, opts.cameraToWorld)
  inc stats.numPrimaryRays
  trace(ray, scene.objects, stats)
  result = shade(ray, opts.bgColor)


proc calcPixelGridAA(scene: Scene, opts: Options, x, y: int, size: int,
                     stats: var Stats): Vec3[float] =

  let
    nSamples = size * size
    gridSize = 1.0 / float(size)

  var samples = newSeq[Vec3[float]](nSamples)

  for j in 0..<size:
    for i in 0..<size:
      var
        xoffs = float(i) * gridSize + gridSize * 0.5
        yoffs = float(j) * gridSize + gridSize * 0.5
        ray = primaryRay(opts.width, opts.height, x, y, xoffs, yoffs,
                         opts.fov, opts.cameraToWorld)
      inc stats.numPrimaryRays
      trace(ray, scene.objects, stats)
      samples[j * size + i] = shade(ray, opts.bgColor)

  var
    color = vec3(0.0)

  for i in 0..samples.high:
    color = color + samples[i]

  result = color * (1 / float(nSamples))


proc renderLine(scene: Scene, opts: Options,
                fb: var FramebufRef, line: int): Stats =
  var
    stats = Stats()
    color: Vec3[float]

  for x in 0..<opts.width:
    case opts.antialias.kind:
    of akNone: color = calcPixelNoAA(scene, opts, x, line, stats)
    of akGrid: color = calcPixelGridAA(scene, opts, x, line,
                                       opts.antialias.gridSize, stats)
    fb.set(x, line, color)

  result = stats


proc render(msg: WorkMsg): ResponseMsg =
  let stats = renderLine(msg.scene[], msg.opts, msg.framebuf[], msg.line)
  result = ResponseMsg(stats: stats)


proc initRenderer*(numWorkers, maxWorkers: Natural = 0):
  WorkerPool[WorkMsg, ResponseMsg] =

  result = initWorkerPool[WorkMsg, ResponseMsg](render, numWorkers)

