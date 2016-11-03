import math, random, times


proc readVertex(f: File): Vec3[float32] =
  var buf: float32
  discard f.readBuffer(buf.addr, 4)
  result = vec[float2]()
  result.x = buf
  discard f.readBuffer(buf.addr, 4)
  result.y = buf
  discard f.readBuffer(buf.addr, 4)
  result.z = buf


proc loadGeom(fname: string): seq[Vec3[float32]] =
  var f: File
  discard open(f, fname)

  var numTriangles: int32
  discard f.readBuffer(numTriangles.addr, 4)

  result = newSeq[Vec3[float32]](numTriangles * 3)

  for i in 0..<numTriangles:
    result[i*3    ] = readVertex(f)
    result[i*3 + 1] = readVertex(f)
    result[i*3 + 2] = readVertex(f)


proc generateGeom(numTriangles: int): seq[Vec3[float32]] =
  result = newSeq[Vec3[float32]](numTriangles * 3)

  for i in 0..<numTriangles:
    result[i*3    ] = random(1.0)
    result[i*3 + 1] = random(1.0)
    result[i*3 + 2] = random(1.0)


proc randomSphere(): Vec3[float32] =
  let
    r1 = random(1.0)
    r2 = random(1.0)
    lat = arccos(2*r1 - 1) - PI/2
    lon = 2*PI * r2

  result = vec3(cos(lat) * cos(lon),
                cos(lat) * sin(lon),
                sin(lat))


#let triangles = loadGeom("bunny.geom")
let triangles = generateGeom(100_000)

var r = Ray()
var t = 0.0

let NUM_RAYS = 1000
let tStart = epochTime()

for j in 0..<NUM_RAYS:
  r.orig = randomSphere() * 10
  r.dir = randomSphere()

  for i in 0..<(triangles.len / 3).int:
    t += rayTriangleIntersect(r, triangles[i  ],
                                 triangles[i+1],
                                 triangles[i+2])

let tTotal = epochTime() - tStart

echo t

let numTests = triangles.len / 3 * NUM_RAYS.float

echo "Total time: " & $tTotal & "s"
echo "Millions of intersection tests per second: " & $(numTests / tTotal / 1_000_000)

