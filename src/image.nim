import endians, math
import glm
import color, mathutils

type
  Image* = object
    w*, h*: int
    data: seq[Color]

  ImageRef* = ref Image


proc newImage*(w, h: int): ImageRef =
  new(result)
  result.w = w
  result.h = h
  result.data = newSeq[Color](w * h)

proc set*(img: var ImageRef, x, y: int, color: Color) =
  img.data[y * img.w + x] = color

proc get*(img: var ImageRef, x, y: int): Color =
  result = img.data[y * img.w + x]


proc writePpm*(img: ImageRef, filename: string, bits: range[1..16]): bool =
  var
    f: File
    maxval = float32(2^bits - 1)

  proc writeHeader() =
    f.write("P6 " & $img.w & " " & $img.h & " " & $int(maxval) & " ")

  proc writeUint8(v: int) =
    var buf = uint8(v)
    discard f.writeBuffer(buf.addr, 1)

  proc writeUint16(v: int) =
    var buf = uint16(v)
    var bufBE: uint16
    bigEndian16(bufBE.addr, buf.addr)
    discard f.writeBuffer(bufBE.addr, 2)

  var writeComponent = if bits <= 8: writeUint8 else: writeUint16

  if open(f, filename, fmWrite):
    try:
      writeHeader()
      for c in img.data:
        writeComponent(round(clamp(c.r, 0.0, 1.0) * maxval))
        writeComponent(round(clamp(c.g, 0.0, 1.0) * maxval))
        writeComponent(round(clamp(c.b, 0.0, 1.0) * maxval))
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

  var image = newImage(W, H)

  var r, g, b: float
  image.set(0, 0, color(0.2, 0.6, 0.5))
  var col = image.get(0, 0)

  assert eq(col.r, 0.2)
  assert eq(col.g, 0.6)
  assert eq(col.b, 0.5)

  image.set(W-1, H-1, color(1.0, 0.9, 0.1))
  col = image.get(W-1, H-1)

  assert eq(col.r, 1.0)
  assert eq(col.g, 0.9)
  assert eq(col.b, 0.1)

  for y in 0..<image.h:
    for x in 0..<image.w:
      let col = color(y / (image.h-1),
                      x / (image.w-1),
                      (image.h-1 - y) / (image.h-1))
      image.set(x, y, col)

  assert image.writePpm("test-8bit.ppm", 8) == true
  assert image.writePpm("test-16bit.ppm", 16) == true

