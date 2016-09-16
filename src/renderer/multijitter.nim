import math

proc multiJitter(n: Natural) =
  var p = newSeq[string]((n * n)^2)
  for i in 0..p.high:
    p[i] = "."

  let m = n*n

  for j in 0..<n:
    for i in 0..<n:
      p[j*m*n+j + i*(m+n)] = $i

  for j in 0..<m:
    for i in 0..<m:
      stdout.write p[j*m + i] & " "
    stdout.write "\n"


multiJitter(4)
