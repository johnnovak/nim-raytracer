import math
import glm
import framebuf
import color
import random


let
  WIDTH = 1024
  HEIGHT = 100


# Linear ramp
var fb = newFramebuf(WIDTH, HEIGHT)

let
  nRects = 32
  rectWidth = WIDTH / nRects
  step = 1.0 / float(nRects)

for i in 0..<nRects:
  let
    b = step * float(i)
    c = vec3[float32](b, b, b)
    ox = Natural(float(i) * rectWidth)

  fb.rect(ox, 0, Natural(rectWidth), HEIGHT, c)

discard fb.writePpm("linear-ramp32.ppm")


# Gamma corrected ramp (32 shades)
fb = newFramebuf(WIDTH, HEIGHT)

for i in 0..<nRects:
  let
    b = pow(step * float(i), 2.2)
    c = vec3[float32](b, b, b)
    ox = Natural(float(i) * rectWidth)

  fb.rect(ox, 0, Natural(rectWidth), HEIGHT, c)

discard fb.writePpm("gamma-ramp32.ppm")


# Perceptually correct linear ramp (256 shades)
fb = newFramebuf(WIDTH, HEIGHT)

for x in 0..<WIDTH:
  let
    b = pow(x / WIDTH, 2.2)
    c = vec3[float32](b, b, b)

  fb.rect(x, 0, 1, HEIGHT, c)

discard fb.writePpm("linear-ramp.ppm")


# Perceptually correct linear ramp (32 shades)
fb = newFramebuf(WIDTH, HEIGHT)

for x in 0..<WIDTH:
  let
    b = pow(x / WIDTH, 2.2)
    q = round(b * 32) / 32
    c = vec3[float32](q, q, q)

  fb.rect(x, 0, 1, HEIGHT, c)

discard fb.writePpm("linear-ramp32-perceptual.ppm")

