import ../utils/format


type
  Stats* = object
    numPrimaryRays*: Natural
    numIntersectionTests*: Natural
    numIntersectionHits*: Natural

proc `+=`*(l: var Stats, r: Stats) =
  l.numPrimaryRays += r.numPrimaryRays
  l.numIntersectionTests += r.numIntersectionTests
  l.numIntersectionHits += r.numIntersectionHits

proc `$`*(s: Stats): string =
  let percHits = s.numIntersectionHits / s.numIntersectionTests * 100
  result =   "numPrimaryRays:       " & $s.numPrimaryRays | 16 &
           "\nnumIntersectionTests: " & $s.numIntersectionTests | 16 &
           "\nnumIntersectionHits:  " & $s.numIntersectionHits | 16 &
           " (" & percHits | (1, 2) & "% of total tests)"

