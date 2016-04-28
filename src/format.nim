# Inspired by Jehan, source: http://forum.nim-lang.org/t/799/1

import math, strutils

proc `|`*(x: int, d: int): string =
  result = $x
  let pad = repeat('0', max(d.abs - len(result), 0))
  if d >= 0:
    result = pad & result
  else:
    result = result & pad

proc `|`*(s: string, d: int): string =
  let pad = spaces(max(d.abs - len(s), 0))
  if d >= 0:
    result = pad & s
  else:
    result = s & pad

proc `|`*(f: float, d: tuple[w,p: int]): string =
  result = formatFloat(f, ffDecimal, d.p)
  let pad = repeat('0', max(d.w.abs - len(result), 0))
  if d.w >= 0:
    result = pad & result
  else:
    result = result & pad

proc `|`*(f: float, d: int): string =
  $f | d


proc formatDuration*(seconds: float): string =
  const
    SECONDS_IN_MINUTE = 60
    SECONDS_IN_HOUR = 60 * SECONDS_IN_MINUTE

  var secs = seconds.int
  var hours = secs div SECONDS_IN_HOUR
  secs -= hours * SECONDS_IN_HOUR
  var minutes = secs div SECONDS_IN_MINUTE
  secs -= minutes * SECONDS_IN_MINUTE

  result = hours | 2 & ":" & minutes | 2 & ":" & secs | 2


when isMainModule:
  echo "|$1|$2|$3|".format("foo" | -10, 7.1 | (6, 2), $3 | 5)
  var f = 13.4
  echo f | 6
  echo f | (3, 2)
  echo formatSeconds(3723)
