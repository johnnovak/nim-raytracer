import os, strutils

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
    y = parseFloat(ys)
  except ValueError:
    discard  # TODO

  try:
    z = parseFloat(zs)
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


#[
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
]#

proc loadObj*(fname: string): (seq[Vec4[float]], seq[Triangle]) =
  var (numVerts, numFaces) = countFacesAndVertices(fname)

  var
    vertices, normals: seq[Vec4[float]]
    faces: seq[Triangle]

  newSeq(vertices, numVerts)
  newSeq(faces, numFaces)

  var
    vertIdx = 0
    faceIdx = 0

  for line in lines(fname):
    let c = splitWhitespace(line)
    if c.len == 0:  # empty line
      continue

    case c[0]:
    of "v":   # vertex
      vertices[vertIdx] = toVertex(c[1], c[2], c[3])
      vertIdx += 1
      if vertIdx >= numVerts:
        discard  # TODO

    of "f":   # face
      let t = Triangle()
      t.vertexIdx = toFaceIdx(c[1], c[2], c[3])
      faces[faceIdx] = t
      faceIdx += 1
      if faceIdx > numFaces:
        discard  # TODO

  result = (vertices, faces)


proc write(f: File, v: Vec4[float]) =
  var buf = v.x.float32
  # TODO
  discard f.writeBuffer(buf.addr, 4)

  buf = v.y.float32
  # TODO
  discard f.writeBuffer(buf.addr, 4)

  buf = v.z.float32
  # TODO
  discard f.writeBuffer(buf.addr, 4)


proc writeGeom(fname: string, vertices: seq[Vec4[float]],
               faces: seq[Triangle]) =
  var f: File
  # TODO
  discard open(f, fname, fmWrite)

  var buf = faces.len.int32
  discard f.writeBuffer(buf.addr, 4)

  for t in faces:
    f.write(vertices[t.vertexIdx[0]])
    f.write(vertices[t.vertexIdx[1]])
    f.write(vertices[t.vertexIdx[2]])

  close(f)


proc main() =
  let args = commandLineParams()
  if args.len != 2:
    echo "Usage: objconv INFILE OUTFILE"
    quit(QuitFailure)

  let
    infile = args[0]
    outfile = args[1]

  let
    (vertices, faces) = loadObj(infile)
#    normals = calcNormals(vertices, faces)

  writeGeom(outfile, vertices, faces)


main()

