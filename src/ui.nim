import math
import nanovg
import mathutils

# {{{ color definitions

var
  WHITE = gray(255)
  BLACK = gray(0)

var
  hoverColor        = WHITE
  hoverColorMix     = 0.3

  disabledColorMix  = 0.5

var
  widgetStrokeWidth = 1.8
  widgetOuterEmbossOffsetY = 1.0
  widgetOuterEmbossOffsetX = 0.0
  widgetOuterEmbossColor = WHITE.withAlpha(0.3)

var
  widgetTextFontFace           = "sans"
  widgetTextFontSize           = 13.0
  widgetTextBaselineCorrection = 0.077
  widgetTextShadowBlur         = 0.0
  widgetTextShadowBrightness   = 1.0
  widgetTextShadowAlpha        = 0.3
  widgetTextShadowOffsetX      = 0.0
  widgetTextShadowOffsetY      = 1.0

  # cached values
  widgetTextShadowColor: Color

var
  panelBgColor= gray(153, 200)

  textDefaultColor         = gray(10)

  buttonCornerRadius       = 4.0
  buttonOutlineColor       = gray(30)
  buttonInnerColor         = gray(180)
  buttonInnerSelectedColor = gray(100)
  buttonTextColor          = BLACK
  buttonTextSelectedColor  = WHITE
  buttonShadeTop           = 0.25
  buttonShadeBottom        = -0.25

  progressBarCornerRadius  = 2.0
  progressBarOutlineColor  = gray(30)
  progressBarTextColor     = WHITE
  progressBarInnerColor    = gray(100)
  progressBarItemColor     = color(70, 160, 240)
  progressBarShadeTop      = -0.2
  progressBarShadeBottom   = 0.0

# }}}
# {{{ color helper functions

proc shadeColor(s: float): Color =
  if s < 0:
    result = BLACK.withAlpha(-s)
  else:
    result = WHITE.withAlpha(s)

proc shadowColor(brightness, alpha: float): Color =
  if brightness < 0:
    result = BLACK.withAlpha(alpha)
  else:
    result = WHITE.withAlpha(alpha)

proc disabledColor(c: Color): Color =
  result = mix(c, panelBgColor, disabledColorMix).withAlpha(c.a)

# }}}

# {{{ UI

type UIStateObj = object
  mx, my: float
  mbLeftDown: bool
  mbRightDown: bool
  hotItem: Natural
  activeItem: Natural

var state = UIStateObj()

var
  fontNormal, fontBold: int
  vg: NVGContext

proc setUIContext*(ctx: NVGContext) =
  vg = ctx

proc updatePrecalcValues() =
  widgetTextShadowColor = shadowColor(widgetTextShadowBrightness,
                                      widgetTextShadowAlpha)

proc initUI*(): bool =
  if vg == nil:
    return false

#  fontNormal = vg.createFont("sans", "data/Roboto-Regular.ttf")
  fontNormal = vg.createFont("sans", "data/DejaVuSans.ttf")
#  fontNormal = vg.createFont("sans", "data/DroidSans.ttf")
  if fontNormal == -1:
    echo "Could not load font."
    return false

  fontNormal = vg.createFont("mono", "data/Inconsolata-Regular.ttf")
#  fontNormal = vg.createFont("mono", "data/DroidSansMono.ttf")
  if fontNormal == -1:
    echo "Could not load font."
    return false

  updatePrecalcValues()

  return true


proc beginUI*(mx, my: float, mbLeftDown, mbRightDown: bool) =
  state.mx = mx
  state.my = my
  state.mbLeftDown = mbLeftDown
  state.mbRightDown = mbRightDown
  state.hotItem = 0

proc isHot(x, y, w, h: float): bool =
  result = state.mx >= x and state.mx <= x+w and
           state.my >= y and state.my <= y+h

proc hot(id: Natural): bool {.inline.} = state.hotItem == id
proc active(id: Natural): bool {.inline.} = state.activeItem == id
proc leftMb(): bool {.inline.} = state.mbLeftDown

# }}}

# {{{ leftRoundedRect

# Length proportional to radius of a cubic bezier handle for 90deg arcs
let KAPPA90 = 0.5522847493

proc leftRoundedRect(x, y, w, h, r: float) =
  if r < 0.1:
    vg.rect(x, y, w, h)
  else:
    var
      rx = min(r, abs(w) * 0.5) * sign(w)
      ry = min(r, abs(h) * 0.5) * sign(h)

    vg.moveTo(x, y+ry)
    vg.lineTo(x, y+h-ry)
    vg.bezierTo(x, y+h-ry*(1-KAPPA90), x+rx*(1-KAPPA90), y+h, x+rx, y+h)
    vg.lineTo(x+w, y+h)
    vg.lineTo(x+w, y)
    vg.lineTo(x+rx, y)
    vg.bezierTo(x+rx*(1-KAPPA90), y, x, y+ry*(1-KAPPA90), x, y+ry)
    vg.closePath()

# }}}
# {{{ rightRoundedRect

proc rightRoundedRect(x, y, w, h, r: float) =
  if r < 0.1:
    vg.rect(x, y, w, h)
  else:
    var
      rx = min(r, abs(w) * 0.5) * sign(w)
      ry = min(r, abs(h) * 0.5) * sign(h)

    vg.moveTo(x, y)
    vg.lineTo(x, y+h)
    vg.lineTo(x+w-rx, y+h)
    vg.bezierTo(x+w-rx*(1-KAPPA90), y+h, x+w, y+h-ry*(1-KAPPA90), x+w, y+h-ry)
    vg.lineTo(x+w, y+ry)
    vg.bezierTo(x+w, y+ry*(1-KAPPA90), x+w-rx*(1-KAPPA90), y, x+w-rx, y)
    vg.closePath()

# }}}
# {{{ widgetText

proc widgetText(x, y, w, h: float, text: string,
                textColor, textShadowColor: Color,
                halign: HorizAlign = haCenter,
                valign: VertAlign = vaMiddle) =

  vg.fontFace(widgetTextFontFace)
  vg.fontSize(widgetTextFontSize)

  var tx, ty: float

  case halign
  of haLeft:   tx = x
  of haCenter: tx = x + floor(w/2)
  of haRight:  tx = x + w

  case valign
  of vaTop:      ty = y
  of vaMiddle:   ty = y + floor(h/2)
  of vaBottom:   ty = y + h
  of vaBaseline: ty = y # TODO: custom align enum?

  vg.textAlign(halign, valign)

  let ycorr = widgetTextFontSize.float * widgetTextBaselineCorrection
  ty += ycorr

  vg.fillColor(textShadowColor)
  discard vg.text(tx + widgetTextShadowOffsetX,
                  ty + widgetTextShadowOffsetY, text)

  vg.fillColor(textColor)
  discard vg.text(tx, ty, text)

# }}}
# {{{ label

proc label*(x, y, w, h: float, text: string,
            textColor: Color = textDefaultColor,
            textShadowColor: Color = BLACK.withAlpha(0),
            halign: HorizAlign = haCenter,
            valign: VertAlign = vaMiddle) =

  widgetText(x, y, w, h, text, textColor, textShadowColor, halign, valign)

# }}}
# {{{ button

proc button*(id: int, x, y, w, h: float, label: string,
             disabled: bool = false): bool =

  if not disabled and isHot(x, y, w, h):
    state.hotItem = id

  if not disabled and hot(id) and leftMb():
    state.activeItem = id

  if active(id) and not leftMb():
    state.activeItem = 0
    result = hot(id)

  var
    outlineColor = buttonOutlineColor
    innerColor, textColor, textShadowColor: Color
    shadeTop, shadeBottom: Color

  if active(id) and leftMb():
      innerColor      = buttonInnerSelectedColor
      shadeTop        = shadeColor(buttonShadeBottom)
      shadeBottom     = shadeColor(buttonShadeTop)
      textColor       = buttonTextSelectedColor
      textShadowColor = BLACK.withAlpha(0)

  else:
    if hot(id):
      innerColor = mix(buttonInnerColor, hoverColor, hoverColorMix)
    else:
      innerColor = buttonInnerColor

    shadeTop        = shadeColor(buttonShadeTop)
    shadeBottom     = shadeColor(buttonShadeBottom)
    textColor       = buttonTextColor
    textShadowColor = widgetTextShadowColor

    if disabled:
      outlineColor    = disabledColor(outlineColor)
      innerColor      = disabledColor(innerColor)
      shadeTop        = disabledColor(shadeTop)
      shadeBottom     = disabledColor(shadeBottom)
      textColor       = disabledColor(textColor)
      textShadowColor = disabledColor(textShadowColor)

  # outer emboss
  vg.beginPath()
  vg.roundedRect(x + widgetOuterEmbossOffsetX,
                 y + widgetOuterEmbossOffsetY, w, h, buttonCornerRadius)
  vg.strokeColor(widgetOuterEmbossColor)
  vg.strokeWidth(widgetStrokeWidth)
  vg.stroke()

  # outline
  vg.beginPath()
  vg.roundedRect(x, y, w, h, buttonCornerRadius)
  vg.strokeColor(outlineColor)
  vg.strokeWidth(widgetStrokeWidth)
  vg.stroke()

  # inner fill
  vg.fillColor(innerColor)
  vg.fill()

  # gradient overlay
  vg.fillPaint(vg.linearGradient(x, y, x, y+h, shadeTop, shadeBottom))
  vg.fill()

  # button text
  widgetText(x, y, w, h, label, textColor, textShadowColor)

# }}}
# {{{ panel

proc panel*(id: int, x, y, w, h: float) =
  vg.beginPath()
  vg.fillColor(panelBgColor)
  vg.rect(x, y, w, h)
  vg.fill()

# }}}
# {{{ console

proc console*(x, y, w, h: float, text: string) =
  vg.beginPath()
  vg.rect(x, y, w, h)
  vg.fillColor(gray(100, 130))
  vg.fill()

  vg.fontSize(16)
  vg.textLineHeight(1.2)
  vg.fontFace("mono")
  vg.fillColor(gray(240))
  vg.textAlign(haLeft, vaTop)
  vg.textBox(x, y, w, text)

# }}}
# {{{ progressBar

proc progressBar*(x, y, w, h: float, p: float) =
  # outer emboss
  vg.beginPath()
  vg.roundedRect(x + widgetOuterEmbossOffsetX,
                 y + widgetOuterEmbossOffsetY, w, h, buttonCornerRadius)
  vg.strokeColor(widgetOuterEmbossColor)
  vg.strokeWidth(widgetStrokeWidth)
  vg.stroke()

  # outline
  vg.beginPath()
  vg.roundedRect(x, y, w, h, progressBarCornerRadius)
  vg.strokeWidth(widgetStrokeWidth)
  vg.strokeColor(progressBarOutlineColor)
  vg.stroke()

  # inner fill
  vg.fillColor(progressBarInnerColor)
  vg.fill()

  vg.fillPaint(vg.boxGradient(x+1, y+1, w, h, progressBarCornerRadius, 5.0,
                              progressBarInnerColor, BLACK.withAlpha(0.3)))
  vg.fill()

  # progress
  let pw = round(p * w).float

  if pw > 0:
    vg.beginPath()
    if pw < w - progressBarCornerRadius:
      leftRoundedRect(x, y, pw, h, progressBarCornerRadius)
    else:
      vg.roundedRect(x, y, pw, h, progressBarCornerRadius)
    vg.fillColor(progressBarItemColor)
    vg.fill()

  # gradient overlay
  vg.beginPath()
  vg.roundedRect(x, y, w, h, progressBarCornerRadius)

  vg.fillPaint(vg.linearGradient(x, y, x, y+h,
                                 shadeColor(progressBarShadeTop),
                                 shadeColor(progressBarShadeBottom)))
  vg.fill()

  # progress indicator text
  widgetText(x, y, w, h, $(p * 100).int & "%", progressBarTextColor,
             BLACK.withAlpha(0.4)) # TODO shadow from config?
# }}}

# vim: foldmethod=marker
