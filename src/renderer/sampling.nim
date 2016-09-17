import math, random
import glm


proc grid*(m, n: Natural): seq[Vec2[float]] =
  let
    xs = 1.0 / float(n)
    ys = 1.0 / float(m)
    xoffs = xs * 0.5
    yoffs = xs * 0.5

  var p = newSeq[Vec2[float]](m * n)

  for j in 0..<m:
    for i in 0..<n:
      p[j*m + i] = vec2(i.float * xs + xoffs,
                        j.float * ys + yoffs)
  result = p


proc jitteredGrid*(m, n: Natural): seq[Vec2[float]] =
  let
    xs = 1.0 / n.float
    ys = 1.0 / m.float

  var p = newSeq[Vec2[float]](m * n)

  for j in 0..<m:
    for i in 0..<n:
      p[j*m + i] = vec2(i.float * xs + random(xs),
                        j.float * ys + random(ys))
  result = p


# Multi-jitter sampling
# http://graphics.pixar.com/library/MultiJitteredSampling/paper.pdf

proc multiJittered*(n, m: Natural): seq[Vec2[float]] =
  let
    xs = 1.0 / float(n)
    ys = 1.0 / float(m)

  var p = newSeq[Vec2[float]](m * n)

  # Canonical arrangement
  for j in 0..<n:
    let jj = j.float
    for i in 0..<m:
      let ii = i.float
      p[j*m + i] = vec2((ii + (jj + random(1.0)) * xs) * ys,
                        (jj + (ii + random(1.0)) * ys) * xs)

  # Shuffle
  for j in 0..<n:
    for i in 0..<m:
      let
        k = j + (random(1.0) * (n-j).float).int
        a = j*m + i
        b = k*m + i
      let tmp = p[a].x
      p[a].x = p[b].x
      p[b].x = tmp

  for i in 0..<m:
    for j in 0..<n:
      let
        k = i + (random(1.0) * (m-i).float).int
        a = j*m + i
        b = j*m + k
      let tmp = p[a].y
      p[a].y = p[b].y
      p[b].y = tmp

  result = p


proc correlatedMultiJittered*(n, m: Natural): seq[Vec2[float]] =
  let
    xs = 1.0 / float(n)
    ys = 1.0 / float(m)

  var p = newSeq[Vec2[float]](m * n)

  # Canonical arrangement
  for j in 0..<n:
    let jj = j.float
    for i in 0..<m:
      let ii = i.float
      p[j*m + i] = vec2((ii + (jj + random(1.0)) * xs) * ys,
                        (jj + (ii + random(1.0)) * ys) * xs)

  # Shuffle
  for j in 0..<n:
    let k = j + (random(1.0) * (n-j).float).int
    for i in 0..<m:
      let
        a = j*m + i
        b = k*m + i
      let tmp = p[a].x
      p[a].x = p[b].x
      p[b].x = tmp

  for i in 0..<m:
    let k = i + (random(1.0) * (m-i).float).int
    for j in 0..<n:
      let
        a = j*m + i
        b = j*m + k
      let tmp = p[a].y
      p[a].y = p[b].y
      p[b].y = tmp

  result = p

