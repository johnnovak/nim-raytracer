import math, random, times


proc readVertex(f: File): Vec3 =
  var buf: float32
  discard f.readBuffer(buf.addr, 4)
  result = Vec3()
  result.x = buf
  discard f.readBuffer(buf.addr, 4)
  result.y = buf
  discard f.readBuffer(buf.addr, 4)
  result.z = buf

proc loadGeom(fname: string): seq[Vec3] =
  var f: File
  discard open(f, fname)

  var numTriangles: int32
  discard f.readBuffer(numTriangles.addr, 4)

  result = newSeq[Vec3](numTriangles * 3)

  for i in 0..<numTriangles:
    result[i*3 + 0] = readVertex(f)
    result[i*3 + 1] = readVertex(f)
    result[i*3 + 2] = readVertex(f)


proc randomVertex: Vec3 =
  result = vec3(random(2.0) - 1.0,
                random(2.0) - 1.0,
                random(2.0) - 1.0)

proc generateRandomTriangles(numTriangles: int): seq[Vec3] =
  result = newSeq[Vec3](numTriangles * 3)

  for i in 0..<numTriangles:
    result[i*3 + 0] = randomVertex()
    result[i*3 + 1] = randomVertex()
    result[i*3 + 2] = randomVertex()


proc randomSphere(): Vec3 =
  let
    r1 = random(1.0)
    r2 = random(1.0)
    lat = arccos(2*r1 - 1) - PI/2
    lon = 2*PI * r2

  result = vec3(cos(lat) * cos(lon),
                cos(lat) * sin(lon),
                sin(lat))


let NUM_RAYS = 1000
let NUM_TRIANGLES = 100 * 1000

randomize()

#let vertices = loadGeom("bunny.geom")
let vertices = generateRandomTriangles(NUM_TRIANGLES)

#for v in vertices:
#  echo v
#quit(0)


var
  r = Ray()
  dummy = 0.0
  numHit = 0
  numMiss = 0

let tStart = epochTime()

for j in 0..<NUM_RAYS:
  r.orig = randomSphere()
  r.dir  = randomSphere()
#  r.orig = vec3(0.0, 0.0, 0.0)
#  r.dir  = vec3(0.0, 1.0, 0.0)

  for i in 0..<(vertices.len / 3).int:
    let t = rayTriangleIntersect(r, vertices[i*3 + 0],
                                    vertices[i*3 + 1],
                                    vertices[i*3 + 2])
#    echo float6(t)
    dummy += t

    if t >= 0:
      numHit += 1
    else:
      numMiss += 1

let tTotal = epochTime() - tStart

echo dummy

let numTests = NUM_TRIANGLES * NUM_RAYS

echo "Total intersection tests:  " & $numTests
echo "  Hits:                    " & $numHit
echo "  Misses:                  " & $numMiss
echo ""
echo "Total time:                    " & $tTotal
echo "Millions of tests per second:  " & $(numTests.float / tTotal / 1_000_000)

