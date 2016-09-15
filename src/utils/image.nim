import math

import framebuf


type
  ImageRGBAObj = object
    w*, h*: Natural
    data*: seq[uint8]

  ImageRGBA* = ref ImageRGBAObj


proc initImageRGBA*(w, h: Natural): ImageRGBA =
  assert w > 0
  assert h > 0
  new(result)
  result.w = w
  result.h = h
  result.data = newSeq[uint8](w * h * 4)

proc caddr*(img: ImageRGBA): ptr cuchar =
  result = cast[ptr cuchar](img.data[0].addr)

proc `[]=`*(img: var ImageRGBA, x, y: Natural, r, g, b: uint8,
            a: uint8 = 255) =
  assert x < img.w
  assert y < img.h
  let offs = (y * img.w + x) * 4
  img.data[offs  ] = r
  img.data[offs+1] = g
  img.data[offs+2] = b
  img.data[offs+3] = a

proc `[]`*(img: var ImageRGBA, x, y: Natural): tuple[r, g, b, a: uint8] =
  assert x < img.w
  assert y < img.h
  let offs = (y * img.w + x) * 4
  result = (img.data[offs  ],
            img.data[offs+1],
            img.data[offs+2],
            img.data[offs+3])


proc copyFrom*(img: var ImageRGBA, fb: Framebuf, alpha: uint8 = 0xff) =
  assert img.w == fb.w
  assert img.h == fb.h
  var p = 0
  for i in countup(0, fb.data.high, 3):
    img.data[p  ] = round(fb.data[i  ] * 0xff).uint8
    img.data[p+1] = round(fb.data[i+1] * 0xff).uint8
    img.data[p+2] = round(fb.data[i+2] * 0xff).uint8
    img.data[p+3] = alpha
    p += 4

