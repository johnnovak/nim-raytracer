import unittest, times

import glm

import renderer/geom
import utils/mathutils


suite "box test":

  test "performance test":
    let box = AABB(vmin: point(-1.0, -1.0, -1.0),
                   vmax: point(1.0, 1.0, 1.0))

    let ray = initRay(orig = point(0.0, 0.0, 2.0),
                      dir = vec(0.3, 0.4, -1.0).normalize)


    let tStart = epochTime()

    let N = 100_000_000

    for i in 0..N:
      let t = intersect(box, ray)

    let tTotal = epochTime() - tStart

    echo "Total time: " & $tTotal & "s"
    echo "Millions of intersections per second: " & $(N.float / tTotal / 1_000_000)

  test "NaN":
    let r = initRay(orig = point(1.0, 6.107502721898089, 2.280002303070644),
                    dir = vec(0.0, 0.06332703314645494, -0.9979928290688606))


    let b = initBox(
      objectToWorld = mat4(1.0).translate(vec3(0.0, 1.0, -10.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0))

    let t = intersect(b, r)
    echo t
