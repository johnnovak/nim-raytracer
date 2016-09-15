import math
import glm
import framebuf
import color
import random


proc lerp(a, b, t: float): float {.inline.} =
  assert t >= 0.0 and t <= 1.0
  a * (1-t) + b * t


let
  nMax = 16

var
  noise1D = newSeq[float](nMax)

randomize()
for i in 0..noise1D.high:
  noise1D[i] = random(1.0)

proc getNoise1D*(p: float): float =
  echo noise1D.len
  let
    i = p.int
    t = p - i.float
    a = i and nMax-1
    b = (i+1) and nMax-1
  result = lerp(noise1D[a], noise1D[b], t)

# --------------------------------------------------------------------------

let
  WIDTH = 1000
  HEIGHT = 40
  STEP = 8

var
  fb = newFramebuf(WIDTH, HEIGHT)

for x in 0..<WIDTH:
  let
    color = vec3(1.0, 0.0, 0.0)
    y = getNoise1D((x.float - WIDTH.float / 2) / 10.0) * (HEIGHT-1).float
  fb.set(x, y.int, color)

discard fb.writePpm("noise.ppm")


max 16

1.3

i = 1
t = .3
a = 1
b = 2
t = 0.3


-1.3

i = -1
t = .3
a = -1 & 15 = 15
b = -2 & 15 = 14
t = 0.7

