import glm
import math

import image
import geom
import mathutils
import workerpool


const
  W = 1920
  H = 1080
  FOV = 50.0
  BG_COLOR = vec3[float32](0.3, 0.5, 0.7)

var
  img = newImage(W, H)

  objects = @[
    Plane(o: vec3(0.0, -2.0, 0.0),
          n: vec3(0.0, 1.0, 0.0),
          color: vec3[float32](1.0, 1.0, 1.0)),

    Sphere(o: vec3(-5.0, 0.0, -15.0),
           r: 2,
           color: vec3[float32](0.9, 0.3, 0.2)),

    Sphere(o: vec3(-1.0, 0.0, -10.0),
           r: 2,
           color: vec3[float32](0.3, 0.9, 0.2)),

    Sphere(o: vec3(5.0, 0.0, -15.0),
           r: 2,
           color: vec3[float32](0.2, 0.3, 0.9)),

    Sphere(o: vec3(0.0, 0.0, -38.0),
           r: 2,
           color: vec3[float32](0.9, 0.8, 0.2)),

    Sphere(o: vec3(6.0, 0.0, -30.0),
           r: 2,
           color: vec3[float32](0.6, 0.5, 0.9))
  ]


proc primaryRay(w, h, x, y: int, xoffs, yoffs: float, fov: float,
                camera: Mat4x4[float]): Ray =
  var
    r = w / h
    f = tan(degToRad(fov) / 2)
    cx = ((2 * (float(x) + xoffs) * r) / float(w) - r) * f
    cy = (1 - 2 * (float(y) + yoffs) / float(h)) * f

  # TODO translate properly
  var o = vec3(1.0, 4.0, -3.0)
  var dir = camera * vec4(cx, cy, -1, 0).normalize

  result = Ray(o: o, dir: dir.xyz)


proc trace(ray: var Ray) =
  var
    tmin = Inf
    objmin: Object = nil

  for obj in objects:
    var hit = obj.intersect(ray)
    if hit and ray.tHit < tmin:
      tmin = ray.tHit
      objmin = obj

  ray.tHit = tmin
  ray.objHit = objmin


proc shade(ray: Ray): Vec3[float32] =
  if ray.objHit == nil:
    result = BG_COLOR
  else:
    var o: Object = ray.objHit
    result = o.getShade(ray)


proc calcPixelNoAA(im: var ImageRef, x, y: int, fov: float,
                   camera: Mat4x4[float]): Vec3[float32] =

  var ray = primaryRay(im.w, im.h, x, y, 0.5, 0.5, fov, camera)
  trace(ray)
  result = shade(ray)


proc calcPixelAA(im: var ImageRef, x, y: int, fov: float,
                 camera: Mat4x4[float], size: int): Vec3[float32] =

  var
    nSamples = size * size
    samples = newSeq[Vec3[float32]](nSamples)
    gridsize = 1.0 / float(size)

  for j in 0..size-1:
    for i in 0..size-1:
      var
        xoffs = float(i) * gridsize + gridsize * 0.5
        yoffs = float(j) * gridsize + gridsize * 0.5
        ray = primaryRay(im.w, im.h, x, y, xoffs, yoffs, fov, camera)
      trace(ray)
      samples[j * size + i] = shade(ray)

  var
    color = vec3[float32](0, 0, 0)

  for i in 0..samples.high:
    color = color + samples[i]

  result = color / float(nSamples)


proc renderLine(im: var ImageRef, line: int, fov: float) =
  var camera = mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))

  for x in 0..im.w-1:
    var color = calcPixelAA(im, x, line, fov, camera, 4)
    im.set(x, line, color)


proc render(im: var ImageRef, fov: float) =
  for y in 0..im.h-1:
    renderLine(img, y, fov)



type
  WorkMsg = object
    line: int
    img: ptr ImageRef

  ResponseMsg = object
    line: int


proc doWork(msg: WorkMsg): ResponseMsg =
  renderLine(msg.img[], msg.line, FOV)


#render(img, FOV)
#discard img.writePpm("render.ppm", 8)


var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)
let numLines = H

for i in 0..<numLines:
  let msg = WorkMsg(line: i, img: img.addr)
  wp.queueWork(msg)

var numResponses = 0
while numResponses != numLines:
  cpuRelax()
  var (available, response) = wp.receiveResult()
  if (available):
    inc numResponses

wp.close()

discard img.writePpm("render.ppm", 8)
