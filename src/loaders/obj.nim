import strutils

import glm

import ../renderer/geom


proc countFacesAndVertices(fname: string): (int, int) =
  var
    numVerts = 0
    numFaces = 0

  for line in lines(fname):
    let c = splitWhitespace(line)
    if c.len == 0:  # empty line
      continue

    case c[0]:
    of "v": numVerts += 1
    of "f": numFaces += 1

  result = (numVerts, numFaces)


proc toVertex(xs, ys, zs: string): Vec4[float] =
  var x, y, z: float
  try:
    x = parseFloat(xs)
  except ValueError:
    discard  # TODO

  try:
    y = parseFloat(xs)
  except ValueError:
    discard  # TODO

  try:
    z = parseFloat(xs)
  except ValueError:
    discard  # TODO

  result = vec4(x, y, z, 1.0)


proc toFaceIdx(s1, s2, s3: string): array[3, int] =
  var i1, i2, i3: int
  try:
    i1 = parseInt(s1) - 1
  except ValueError:
    discard  # TODO

  try:
    i2 = parseInt(s2) - 1
  except ValueError:
    discard  # TODO

  try:
    i3 = parseInt(s3) - 1
  except ValueError:
    discard  # TODO

  result = [i1, i2, i3]


proc calcNormals(mesh: TriangleMesh) =
  var normIdx = 0
  for t in mesh.faces:
    let
      p1 = mesh.vertices[t.vertexIdx[0]]
      p2 = mesh.vertices[t.vertexIdx[1]]
      p3 = mesh.vertices[t.vertexIdx[2]]

      n = ((p2 - p1) * (p3 - p1)).normalize

    mesh.normals[normIdx] = n

    t.normalIdx[0] = normIdx
    t.normalIdx[1] = normIdx
    t.normalIdx[2] = normIdx

    normIdx += 1


proc loadObj*(fname: string): TriangleMesh =
  var (numVerts, numFaces) = countFacesAndVertices(fname)

  result = TriangleMesh()
  newSeq(result.vertices, numVerts)
  newSeq(result.faces, numFaces)
  newSeq(result.normals, numFaces)  # we calculate 1 normal per face

  var
    vertIdx = 0
    faceIdx = 0

  for line in lines(fname):
    let c = splitWhitespace(line)
    if c.len == 0:  # empty line
      continue

    case c[0]:
    of "v":   # vertex
      result.vertices[vertIdx] = toVertex(c[1], c[2], c[3])
      vertIdx += 1
      if vertIdx >= numVerts:
        discard  # TODO

    of "f":   # face
      let t = Triangle()
      t.vertexIdx = toFaceIdx(c[1], c[2], c[3])
      result.faces[faceIdx] = t
      faceIdx += 1
      if faceIdx > numFaces:
        discard  # TODO

  calcNormals(result)


when isMainModule:
  let mesh = loadObj("../data/meshes/bunny.obj")

