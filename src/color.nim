import strutils
import glm
import mathutils

type
  Color* = object
    r*, g*, b*: float

proc `$`*(c: Color): string =
  result =  "(r: " & formatFloat(c.r, ffDecimal, 6) &
           ", g: " & formatFloat(c.g, ffDecimal, 6) &
           ", b: " & formatFloat(c.b, ffDecimal, 6) & ")"

proc color*(r, g, b: float): Color = Color(r: r, g: g, b: b)

proc color*(rgb: int32): Color =
  result.r = (rgb shr 16 and 0xff) / 0xff
  result.g = (rgb shr  8 and 0xff) / 0xff
  result.b = (rgb        and 0xff) / 0xff

proc `*`*(c: Color, s: float): Color =
  color(c.r * s,
        c.g * s,
        c.b * s)

proc `+`*(x: Color, y: Color): Color =
  color(x.r + y.r,
        x.g + y.g,
        x.b + y.b)


when isMainModule:
  var c1 = color(1.0, 0.4, 0.2)
  assert eq(c1.r, 1.0)
  assert eq(c1.g, 0.4)
  assert eq(c1.b, 0.2)

  var c2 = c1 * 0.5
  assert eq(c2.r, 0.5)
  assert eq(c2.g, 0.2)
  assert eq(c2.b, 0.1)

  var c3 = c1 + c2
  assert eq(c3.r, 1.5)
  assert eq(c3.g, 0.6)
  assert eq(c3.b, 0.3)

  echo c3
  assert $c3 == "(r: 1.500000, g: 0.600000, b: 0.300000)"

