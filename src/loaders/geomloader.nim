import strutils

import glm

import ../renderer/geom


proc calcNormals(normals: var seq[Vec4[float]],
                 vertices: seq[Vec4[float]], faces: seq[Triangle]) =
  var normIdx = 0
  for t in faces:
    let
      p0 = vertices[t.vertexIdx[0]]
      p1 = vertices[t.vertexIdx[1]]
      p2 = vertices[t.vertexIdx[2]]
      v1 = (p1 - p0).xyz
      v2 = (p2 - p0).xyz

      n = v1.cross(v2).normalize

    normals[normIdx] = vec(n.x, n.y, n.z)

    t.normalIdx[0] = normIdx
    t.normalIdx[1] = normIdx
    t.normalIdx[2] = normIdx

    normIdx += 1


proc loadGeom*(fname: string): TriangleMesh =
  var
    vertices, normals: seq[Vec4[float]]
    faces: seq[Triangle]

  var f: File
  open(f, fname)

  var numTriangles: int32
  f.readBuffer(numTriangles, 4)

  newSeq(vertices, numVerts)
  newSeq(faces, numFaces)
  newSeq(normals, numFaces)  # we calculate 1 normal per face

  calcNormals(normals, vertices, faces)

  result = initTriangleMesh(vertices = vertices, normals = normals,
                            faces = faces,
                            objectToWorld = mat4(1.0))


when isMainModule:
  let mesh = loadObj("../data/meshes/bunny.geom")

