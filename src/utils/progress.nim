import strutils

import format
import ../renderer/stats


proc printProgressBar*(currProgress: float) =
  const maxlen = 68
  let
    barlen = int(currProgress * maxlen)
    currprog = $int(currProgress * 100) | 4 & "%"

  let bar = if barlen == 0: "" else:
            repeat('=', max(barlen-1, 0)) & ">"

  echo "[" & bar & spaces(max(maxlen-barlen, 0)) & "]" & currprog


proc printProgress*(currProgress, tCurr, tRemaining: float) =
  printProgressBar(currProgress)
  echo "Ellapsed time: " & formatDuration(tCurr) &
       "\t\tRemaining time: " & formatDuration(tRemaining)

proc printStats*(stats: Stats) =
  echo "\n" & $stats

proc printCompleted*(t: float) =
  echo "\nRendering completed in " & t | (1, 4) & " seconds"

