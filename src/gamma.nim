import math
import glm
import framebuf
import color


let
  WIDTH = 1024
  HEIGHT = 300

var fb = newFramebuf(WIDTH, HEIGHT)

let
  nRects = 64
  rectWidth = WIDTH / nRects
  step = 1.0 / float(nRects)

for i in 0..<nRects:
  let
    b = step * float(i)
    c = vec3[float32](b, b, b)
    ox = Natural(float(i) * rectWidth)

  fb.rect(ox, 0, Natural(rectWidth), 50, c)


for i in 0..<nRects:
  let
    b = pow(step * float(i), 2.2)
    c = vec3[float32](b, b, b)
    ox = Natural(float(i) * rectWidth)

  fb.rect(ox, 60, Natural(rectWidth), 50, c)


for i in 0..<WIDTH:
  let
    c = vec3[float32](1.0 / float(WIDTH / i),
                      1.0 / float(WIDTH / (WIDTH - i)),
                      0.0)

  fb.rect(i, 110, 1, 50, c)

discard fb.writePpm("gamma.ppm")



fb = newFramebuf(WIDTH, HEIGHT)

for i in 0..<WIDTH:
  let
    c = vec3[float32](1.0 / float(WIDTH / i),
                      1.0 / float(WIDTH / (WIDTH - i)),
                      0.0)

  fb.rect(i, 110, 1, 50, c)



fb = newFramebuf(WIDTH, HEIGHT)


for x in 0..<WIDTH:
  let
    x1 = WIDTH / 2 - 15
    x2 = WIDTH / 2 + 15
    xw = x2 - x1

  var r, g: float32

  let xf = float(x)
  if xf < x1:
    r = 0.0
  elif xf < x2:
    r = 1.0 / float(xw / (xf-x1))
  else:
    r = 1.0

  if xf < x1:
    g = 1.0
  elif xf < x2:
    g = 1.0 / float(xw / (xw - (xf-x1)))
  else:
    g = 0.0

  var c = vec3[float32](r, g, 0.0)

  fb.rect(x, 0, 1, 150, c)


  if xf < x1:
    r = 0.0
  elif xf < x2:
    r = 1.0 / float(xw / (xf-x1))
  else:
    r = 1.0

  if xf < x1:
    g = 1.0
  elif xf < x2:
    g = 1.0 / float(xw / (xw - (xf-x1)))
  else:
    g = 0.0

  c = vec3[float32](linearToSRGB(r), linearToSRGB(g), 0.0)

  fb.rect(x, 150, 1, 150, c)


discard fb.writePpm("gamma3.ppm", sRGB = false)

