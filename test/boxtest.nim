import unittest, times

import glm

import renderer/geom


suite "box test":

  test "performance test":
    let box = AABB(vmin: point(-1.0, -1.0, -1.0),
                   vmax: point(1.0, 1.0, 1.0))

    let ray = initRay(orig = point(0.0'f32, 0.0'f32, 2.0'f32),
                      dir = vec(0.3'f32, 0.4'f32, -1.0'f32).normalize)


    let tStart = epochTime()

    let N = 100_000_000

    for i in 0..N:
      let t = intersect(box, ray)

    let tTotal = epochTime() - tStart

    echo "Total time: " & $tTotal & "s"
    echo "Millions of intersections per second: " & $(N.float / tTotal / 1_000_000)
