import times
import random

let
  v1 = vec3(-2.0, -1.0, -5.0)
  v2 = vec3( 2.0, -1.0, -5.0)
  v3 = vec3( 0.0,  1.0, -5.0)

var r = Ray(orig: vec3(0.0, 0.0, 0.0), dir: vec3(0.0, 0.0, -1.0))

let N = 10_000_000
var t = 0.0

let tStart = epochTime()

for i in 0..<N:
  let noise = random(0.000001)
  r.orig.x = noise
  r.orig.y = noise
  r.orig.z = noise
  t += rayTriangleIntersect(r, v1, v2, v3)

let tTotal = epochTime() - tStart

echo t

echo "Total time: " & $tTotal & "s"
echo "Millions of intersection tests per second: " & $(N.float / tTotal / 1_000_000)

