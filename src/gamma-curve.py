#!/usr/bin/env python
# -*- coding: utf-8 -*-

import math
import cairo

WIDTH, HEIGHT = 490, 200

surface = cairo.SVGSurface("gamma.svg", WIDTH, HEIGHT)
ctx = cairo.Context(surface)

# White background
#ctx.set_source_rgb (1.0, 1.0, 1.0)
#ctx.rectangle(0, 0, WIDTH, HEIGHT)
#ctx.fill()

scale_factor = 120
ctx.scale(scale_factor, scale_factor)

def draw_chart(gamma, color):
  ctx.save()
  # Draw coordinate system
  # ---------------------
  ctx.set_line_width (0.006)

  # 45 deg line
  ctx.set_source_rgb (0.7, 0.7, 0.7)
  ctx.move_to(0, 1)
  ctx.line_to(1, 0)
  ctx.stroke()

  # Dashed lines
  ctx.set_dash([0.03, 0.02])

  ctx.move_to(1, 1)
  ctx.line_to(1, 0)
  ctx.stroke()

  ctx.move_to(0, 0)
  ctx.line_to(1, 0)
  ctx.stroke()

  # Y axis
  ctx.set_source_rgb (0.4, 0.4, 0.4)
  ctx.set_line_width (0.01)
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
  ctx.set_font_size(0.11)

  ctx.move_to(0-0.1, 1+0.11)
  ctx.show_text("0")

  ctx.move_to(1-0.03, 1+0.11)
  ctx.show_text("1")

  ctx.move_to(0-0.1, 0+0.06)
  ctx.show_text("1")

  ctx.set_font_size(0.09)
  ctx.move_to(0+0.47, 1+0.11)
  ctx.show_text("in")

  ctx.save()
  ctx.set_font_size(0.09)
  ctx.move_to(0-0.045, 1-0.42)
  ctx.rotate(math.radians(-90))
  ctx.show_text("out")
  ctx.restore()

  # Draw linear approximation of gamma curve
  # ----------------------------------------
  steps = 500

  ctx.set_source_rgb (*color)
  ctx.set_line_width (0.016)
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

ctx.translate(0.17, 0.21)
draw_chart(gamma=1/2.2, color=[1.0, 0.2, 0.5])

ctx.select_font_face("Source Sans Pro")  # image label
ctx.set_font_size(0.11)
ctx.set_source_rgb(0.3, 0.3, 0.3)
ctx.move_to(0+0.27, 1+label_yoffs)
ctx.show_text("a)  ")

ctx.select_font_face("Verdana") # gamma label
ctx.show_text(u"γ")
ctx.select_font_face("Source Sans Pro")
ctx.show_text(u"=1/2.2")

# gamma = 1.2
# -----------
ctx.translate(1.4, 0.0)
draw_chart(gamma=1.0, color=[0.3, 0.7, 0.9])

ctx.select_font_face("Source Sans Pro")  # image label
ctx.move_to(0+0.31, 1+label_yoffs)
ctx.show_text("b)  ")

ctx.select_font_face("Verdana") # gamma label
ctx.show_text(u"γ")
ctx.select_font_face("Source Sans Pro")
ctx.show_text(u"=1.0")

# gamma = 2.2
# -------------
ctx.translate(1.4, 0.0)
draw_chart(gamma=2.2, color=[0.0, 0.6, 0.5])

ctx.select_font_face("Source Sans Pro")  # image label
ctx.move_to(0+0.30, 1+label_yoffs)
ctx.show_text("c)  ")

ctx.select_font_face("Verdana") # gamma label
ctx.show_text(u"γ")
ctx.select_font_face("Source Sans Pro")
ctx.show_text(u"=2.2")

