import math
import glm
import cairo

let
  WIDTH = 490.0
  HEIGHT = 200.0

var
  surface = svgSurfaceCreate("gamma-nim.svg", WIDTH, HEIGHT)
  ctx = create(surface)

# White background
#ctx.set_source_rgb(1.0, 1.0, 1.0)
#ctx.rectangle(0, 0, WIDTH, HEIGHT)
#ctx.fill()

let
  scale_factor = 120.0

ctx.scale(scale_factor, scale_factor)

proc setFont(ctx: PContext, fontname: string) =
  ctx.selectFontFace(fontname, FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)

proc drawChart(gamma: float, color: Vec3[float]) =
  ctx.save()
  # Draw coordinate system
  # ---------------------
  ctx.setLineWidth(0.006)

  # 45 deg line
  ctx.setSourceRgb(0.7, 0.7, 0.7)
  ctx.moveTo(0, 1)
  ctx.lineTo(1, 0)
  ctx.stroke()

  # Dashed lines
  ctx.setDash(@[0.03, 0.02], 0)

  ctx.moveTo(1, 1)
  ctx.lineTo(1, 0)
  ctx.stroke()

  ctx.moveTo(0, 0)
  ctx.lineTo(1, 0)
  ctx.stroke()

  # Y axis
  ctx.setSourceRGB(0.4, 0.4, 0.4)
  ctx.setLineWidth(0.01)
  ctx.setDash(@[], 0)

  var
    d1 = 0.06
    d2 = 0.03

  ctx.moveTo(0, 1+d1)
  ctx.lineTo(0, 0-d2)
  ctx.stroke()

  # X axis
  ctx.moveTo(0-d1, 1)
  ctx.lineTo(1+d2, 1)
  ctx.stroke()

  # Text
  ctx.selectFontFace("Source Sans Pro", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.setFontSize(0.11)

  ctx.moveTo(0-0.1, 1+0.11)
  ctx.showText("0")

  ctx.moveTo(1-0.03, 1+0.11)
  ctx.showText("1")

  ctx.moveTo(0-0.1, 0+0.06)
  ctx.showText("1")

  ctx.setFontSize(0.09)
  ctx.moveTo(0+0.47, 1+0.11)
  ctx.showText("in")

  ctx.save()
  ctx.setFontSize(0.09)
  ctx.moveTo(0-0.045, 1-0.42)
  ctx.rotate(degToRad(-90.0))
  ctx.showText("out")
  ctx.restore()

  # Draw linear approximation of gamma curve
  # ----------------------------------------
  var steps = 500

  ctx.setSourceRGB(color[0], color[1], color[2])
  ctx.setLineWidth(0.016)
  ctx.moveTo(0, 1)

  for i in 0..steps:
    var
      x = float(i) / float(steps)
      y = 1 - pow(x, gamma)
    ctx.lineTo(x, y)

  ctx.stroke()
  ctx.restore()


# gamma = 1/2.2
# -----------
echo "1"
let labelYOffs = 0.35

ctx.translate(0.17, 0.21)
drawChart(gamma=1/2.2, color=vec3(1.0, 0.2, 0.5))

ctx.setFont("Source Sans Pro")  # image label
ctx.setFontSize(0.11)
ctx.setSourceRGB(0.3, 0.3, 0.3)
ctx.moveTo(0+0.27, 1+label_yoffs)
ctx.showText("a)  ")

ctx.setFont("Verdana") # gamma label
ctx.showText("γ")
ctx.setFont("Source Sans Pro")
ctx.showText("=1/2.2")

# gamma = 1.2
# -----------
ctx.translate(1.4, 0.0)
drawChart(gamma=1.0, color=vec3(0.3, 0.7, 0.9))

ctx.setFont("Source Sans Pro")  # image label
ctx.moveTo(0+0.31, 1+label_yoffs)
ctx.showText("b)  ")

ctx.setFont("Verdana") # gamma label
ctx.showText("γ")
ctx.setFont("Source Sans Pro")
ctx.showText("=1.0")

# gamma = 2.2
# -------------
ctx.translate(1.4, 0.0)
drawChart(gamma=2.2, color=vec3(0.0, 0.6, 0.5))

ctx.setFont("Source Sans Pro")  # image label
ctx.moveTo(0+0.30, 1+label_yoffs)
ctx.showText("c)  ")

ctx.setFont("Verdana") # gamma label
ctx.showText("γ")
ctx.setFont("Source Sans Pro")
ctx.showText("=2.2")

ctx.destroy()
surface.destroy()

