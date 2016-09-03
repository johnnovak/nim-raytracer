#!/usr/bin/env python
# -*- coding: utf-8 -*-

import math
import cairo

WIDTH, HEIGHT = 620, 320

surface = cairo.SVGSurface("gamma-encoding.svg", WIDTH, HEIGHT)
ctx = cairo.Context(surface)

# White background
#ctx.set_source_rgb(1.0, 1.0, 1.0)
#ctx.rectangle(0, 0, WIDTH, HEIGHT)
#ctx.fill()

scale_factor = 220
ctx.scale(scale_factor, scale_factor)

def draw_chart(gamma, color):
  ctx.save()
  # Draw coordinate system
  # ---------------------
  ctx.set_line_width(0.006)

  # 45 deg line
  ctx.set_source_rgb(0.8, 0.8, 0.8)
  ctx.move_to(0, 1)
  ctx.line_to(1, 0)
  ctx.stroke()

  # Dashed lines
  ctx.set_line_width(0.004)

  # Input values
  steps = 15

  for i in range(0, steps+1):
    x = float(i) / steps
    y = 1 - math.pow(x, gamma)
    ctx.move_to(x, 1)
    ctx.line_to(x, y)
    ctx.stroke()

  # Output values
  for i in range(0, steps+1):
    x = float(i) / steps
    y = 1 - math.pow(x, gamma)
    ctx.move_to(0-0.2, y)
    ctx.line_to(x, y)
    ctx.stroke()

  # Y axis
  ctx.set_source_rgb(0.4, 0.4, 0.4)
  ctx.set_line_width(0.007)
  ctx.set_dash([])

  d1 = 0.06
  d2 = 0.03

  ctx.move_to(0, 1+d1)
  ctx.line_to(0, 0-d2)
  ctx.stroke()

  # X axis
  ctx.move_to(0-d1, 1)
  ctx.line_to(1+d2, 1)
  ctx.stroke()

  # Text
  ctx.select_font_face("Source Sans Pro")
  ctx.set_font_size(0.07)

  ctx.move_to(0-0.06, 1+0.08)
  ctx.show_text("0")

  ctx.move_to(1-0.02, 1+0.08)
  ctx.show_text("1")

  ctx.move_to(0-0.07, 0-0.03)
  ctx.show_text("1")

  ctx.set_font_size(0.062)
  ctx.move_to(1+0.06, 1+0.02)
  ctx.show_text("in")

  ctx.save()
  ctx.move_to(0, 0-0.08)
  ctx.show_text("out")
  ctx.restore()

  # Draw linear approximation of gamma curve
  # ----------------------------------------
  steps = 500

  ctx.set_source_rgb(*color)
  ctx.set_line_width(0.010)
  ctx.move_to(0, 1)

  for i in range(0, steps+1):
    x = float(i) / steps
    y = 1 - math.pow(x, gamma)
    ctx.line_to(x, y)

  ctx.stroke()
  ctx.restore()


# gamma = 1/2.2
# -----------
label_yoffs = 0.35

ctx.translate(1.2, 0.21)
draw_chart(gamma=1/2.2, color=[1.0, 0.2, 0.5])

ctx.select_font_face("Source Sans Pro")
ctx.set_source_rgb(0.3, 0.3, 0.3)
ctx.set_font_size(0.062)

ctx.move_to(0+0.45, 1+0.08)
ctx.show_text("n=16")

# Encoded values
# --------------
steps = 16
ctx.set_line_width(0.005)

for i in range(0, steps+1):
  y = float(i) / steps
  ctx.move_to(-0.2, y)
  ctx.line_to(-0.4, y)
  ctx.stroke()

ctx.move_to(0-0.365, 1+0.08)
ctx.show_text("Q=16")


steps = 64
ctx.set_line_width(0.005)
ctx.set_source_rgb(0.3, 0.3, 0.3)

for i in range(0, steps+1):
  y = float(i) / steps
  ctx.move_to(-0.4, y)
  ctx.line_to(-0.6, y)
  ctx.stroke()

ctx.move_to(0-0.565, 1+0.08)
ctx.show_text("Q=64")
