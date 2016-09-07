import endians, math
import glm
import color, mathutils

type
  FramebufObj = object
    w*, h*: Natural
    data*: seq[float32]

  Framebuf* = ref FramebufObj


proc newFramebuf*(w, h: Natural): Framebuf =
  new(result)
  result.w = w
  result.h = h
  result.data = newSeq[float32](w * h * 3)


proc set*(fb: var Framebuf, x, y: Natural, color: Vec3[float64]) =
  assert x < fb.w
  assert y < fb.h
  let offs = (y * fb.w + x) * 3
  fb.data[offs    ] = float32(color.r)
  fb.data[offs + 1] = float32(color.g)
  fb.data[offs + 2] = float32(color.b)

proc set*(fb: var Framebuf, x, y: Natural, color: Vec3[float32]) =
  assert x < fb.w
  assert y < fb.h
  let offs = (y * fb.w + x) * 3
  fb.data[offs    ] = color.r
  fb.data[offs + 1] = color.g
  fb.data[offs + 2] = color.b

proc get*(fb: var Framebuf, x, y: Natural): Vec3[float32] =
  assert x < fb.w
  assert y < fb.h
  let offs = (y * fb.w + x) * 3
  result = vec3(fb.data[offs    ],
                fb.data[offs + 1],
                fb.data[offs + 2])


proc rect*(fb: var Framebuf, ox, oy, w, h: Natural, color: Vec3[float32]) =
  for x in ox..<ox+w:
    for y in oy..<oy+h:
      fb.set(x, y, color)


proc writePpm*(fb: Framebuf, filename: string,
               bits: range[1..16] = 8, sRGB: bool = true): bool =
  var
    f: File
    maxval = float32(2^bits - 1)

  proc writeHeader() =
    f.write("P6 " & $fb.w & " " & $fb.h & " " & $int(maxval) & " ")

  proc writeUint8(v: Natural) =
    var buf = uint8(v)
    discard f.writeBuffer(buf.addr, 1)

  proc writeUint16(v: Natural) =
    var buf = uint16(v)
    var bufBE: uint16
    bigEndian16(bufBE.addr, buf.addr)
    discard f.writeBuffer(bufBE.addr, 2)

  proc outvalue(v: float32): Natural =
    var c = clamp(v, 0.0, 1.0)
    if sRGB:
      c = linearToSRGB(c)
    Natural(round(c * maxval))

  var writeComponent = if bits <= 8: writeUint8 else: writeUint16

  if open(f, filename, fmWrite):
    try:
      writeHeader()
      for i in countup(0, fb.data.high, 3):
        writeComponent(outvalue(fb.data[i    ]))
        writeComponent(outvalue(fb.data[i + 1]))
        writeComponent(outvalue(fb.data[i + 2]))
      result = true
    except:
      result = false
    finally:
      f.close


# Tests

when isMainModule:
  const
    W = 1024
    H = 768

  var fb = newFramebuf(W, H)

  var r, g, b: float
  fb.set(0, 0, vec3(0.2, 0.6, 0.5))
  var col = fb.get(0, 0)

  assert eq(col.r, 0.2)
  assert eq(col.g, 0.6)
  assert eq(col.b, 0.5)

  fb.set(W-1, H-1, vec3(1.0, 0.9, 0.1))
  col = fb.get(W-1, H-1)

  assert eq(col.r, 1.0)
  assert eq(col.g, 0.9)
  assert eq(col.b, 0.1)

  for y in 0..<fb.h:
    for x in 0..<fb.w:
      let col = vec3(y / (fb.h-1),
                     x / (fb.w-1),
                     (fb.h-1 - y) / (fb.h-1))
      fb.set(x, y, col)

  assert fb.writePpm("test-8bit.ppm", 8) == true
  assert fb.writePpm("test-16bit.ppm", 16) == true

