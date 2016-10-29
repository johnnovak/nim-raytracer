import times, unittest
import glm
import renderer/geom


suite "geom test":

  test "ray-triangle intersection":
    let
      v0 = vec( 0.0,  1.0, -5.0)
      v1 = vec(-2.0, -1.0, -5.0)
      v2 = vec( 2.0, -1.0, -5.0)

      r = initRay(orig = point(0.0, 0.0, 0.0),
                  dir = vec(0.0, 0.0, -1.0))

    var t = 0.0

    let
      N = 100_000_000
      tStart = epochTime()

    for i in 0..<N:
      t += rayTriangleIntersectFast(r, v0, v1, v2)

    let tTotal = epochTime() - tStart

    echo "Total time: " & $tTotal & "s"
    echo "Millions of intersection tests per second: " & $(N.float / tTotal / 1_000_000)


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
