import unittest
import glm
import renderer/geom


suite "mesh perf test":

  test "ray-triangle intersection":
    let
      v0 = vec( 0.0,  1.0, -5.0)
      v1 = vec(-2.0, -1.0, -5.0)
      v2 = vec( 2.0, -1.0, -5.0)

      r = initRay(orig = point(0.0, 0.0, 0.0),
                  dir = vec(0.0, 0.0, -1.0))

    let t = rayTriangleIntersect(r, v0, v1, v2)

    echo t
    echo r

  test "ray-mesh intersection":
    let
      v0 = vec( 0.0,  1.0, -5.0)
      v1 = vec(-2.0, -1.0, -5.0)
      v2 = vec( 2.0, -1.0, -5.0)

    var
      r = initRay(orig = point(0.0, 0.0, 0.0),
                  dir = vec(0.0, 0.0, -1.0))

    let m = initTriangleMesh(
      vertices = @[v0, v1, v2],
      normals = @[],
      faces = @[Triangle(
        vertexIdx: [0, 1, 2],
        normalIdx: [0, 0, 0])],
      objectToWorld = mat4(1.0)
    )

    let t = m.intersect(r)

    echo t
    echo r
