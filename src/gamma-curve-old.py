#!/usr/bin/env python

import math
import cairo

WIDTH, HEIGHT = 800, 800

surface = cairo.SVGSurface("gamma.svg", WIDTH, HEIGHT)
ctx = cairo.Context(surface)

ctx.set_source_rgb (1.0, 1.0, 1.0)
ctx.rectangle(0, 0, WIDTH, HEIGHT)
ctx.fill()

ctx.set_source_rgb (0.5, 0.5, 0.5)
ctx.set_line_width (4.0)

ys = 500
ye = 100

xs = 100
xe = 600

ctx.move_to(xs, ye - 30)
ctx.line_to(xs, ys + 50)
ctx.close_path()
ctx.stroke()

ctx.move_to(xs - 50, ys)
ctx.line_to(xe + 30, ys)
ctx.close_path()
ctx.stroke()

steps = 500
dx = (xe - xs) / steps

ctx.move_to(xs, ys)
ctx.line_to(xe, ye)
ctx.stroke()

ctx.set_line_width (7.0)
ctx.set_source_rgb (0.8, 0.0, 0.0)
ctx.move_to(xs, ys)

x = xs

for i in range(0, steps+1):
  xn = (x - xs) / float(xe - xs)
  yn = math.pow(xn, 2.2)
  y = ys - yn * (ys - ye)
  ctx.line_to(x, y)
  x = x + dx

ctx.stroke()

ctx.set_source_rgb (0.0, 0.7, 0.0)
ctx.move_to(xs, ys)

x = xs

#for i in range(0, steps+1):
#  xn = (x - xs) / float(xe - xs)
#  yn = math.pow(xn, 1.0/2.2)
#  y = ys - yn * (ys - ye)
#  ctx.line_to(x, y)
#  x = x + dx
#
#ctx.stroke()
