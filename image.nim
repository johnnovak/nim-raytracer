import math
import glm

type
  Image* = object
    w*, h*: int
    data: seq[float32]

  ImageRef* = ref Image


proc newImage*(w, h: int): ImageRef =
  new(result)
  result.w = w
  result.h = h
  result.data = newSeq[float32](w * h * 3)

proc set*(im: var ImageRef, x, y: int, r, g, b: float32) =
  var offs = (y * im.w + x) * 3
  im.data[offs    ] = r
  im.data[offs + 1] = g
  im.data[offs + 2] = b

proc set*(im: var ImageRef, x, y: int, color: Vec3[float32]) =
  var offs = (y * im.w + x) * 3
  im.data[offs    ] = color.r
  im.data[offs + 1] = color.g
  im.data[offs + 2] = color.b

proc get*(im: var ImageRef, x, y: int): (float32, float32, float32) =
  var offs = (y * im.w + x) * 3
  result = (im.data[offs], im.data[offs + 1], im.data[offs + 2])


proc writePpm*(im: ImageRef, filename: string, bits: range[1..16]): bool =
  var
    f: File
    maxval = float32(2^bits - 1)

  if open(f, filename, fmWrite):
    try:
      f.write("P6 " & $im.w & " " & $im.h & " " & $int(maxval) & " ")
      if bits <= 8:
        for c in im.data:
          var buf = uint8(round(c * maxval))
          discard f.writeBuffer(buf.addr, 1)
      else:
        for c in im.data:
          var buf = uint16(round(c * maxval))
          when cpuEndian == littleEndian:
            buf = (buf shr 8) or (buf shl 8)
          discard f.writeBuffer(buf.addr, 2)
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
  image.set(0, 0, 0.2, 0.6, 0.5)
  (r, g, b) = image.get(0, 0)

  assert eq(r, 0.2)
  assert eq(g, 0.6)
  assert eq(b, 0.5)

  image.set(W-1, H-1, 1.0, 0.9, 0.1)
  (r, g, b) = image.get(W-1, H-1)

  assert eq(r, 1.0)
  assert eq(g, 0.9)
  assert eq(b, 0.1)

  for y in 0..image.h-1:
    for x in 0..image.w-1:
      image.set(x, y, y / (image.h-1),
                      x / (image.w-1),
                      (image.h-1 - y) / (image.h-1))

  assert image.writePpm("test-8bit.ppm", 8) == true
  assert image.writePpm("test-16bit.ppm", 16) == true

