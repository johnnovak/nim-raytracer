import math, strutils, terminal, times
import glm

import utils/format
import renderer/renderer


proc formatStats(s: Stats): string =
  let percHits = s.numIntersectionHits / s.numIntersectionTests * 100
  result =   "numPrimaryRays:       " & $s.numPrimaryRays | 16 &
           "\nnumIntersectionTests: " & $s.numIntersectionTests | 16 &
           "\nnumIntersectionHits:  " & $s.numIntersectionHits | 16 &
           " (" & percHits | (1, 2) & "% of total tests)"


proc printProgressBar(currProgress: float) =
  const maxlen = 68
  let
    barlen = int(currProgress * maxlen)
    currprog = $int(currProgress * 100) | 4 & "%"

  let bar = if barlen == 0: "" else:
            repeat('=', max(barlen-1, 0)) & ">"

  echo "[" & bar & spaces(max(maxlen-barlen, 0)) & "]" & currprog


proc printProgress(currProgress, tCurr, tRemaining: float) =
  printProgressBar(currProgress)
  echo "Ellapsed time: " & formatDuration(tCurr) &
       "\t\tRemaining time: " & formatDuration(tRemaining)

proc printStats(stats: Stats) =
  echo "\n" & formatStats(stats)

proc main() =
  let opts = Options(
    width: 600,
    height: 400,
    fov: 50.0,
    cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                            .translate(vec3(1.0, 4.0, -3.0)),
    antialias: Antialias(kind: akGrid, gridSize: 2),
    bgColor: vec3(0.2, 0.4, 0.6)
  )

  let objects = @[
    Sphere(o: point(-5.0, 0.0, -15.0),
           r: 2,
           albedo: vec3(1.0, 0.0, 0.0)),

    Sphere(o: point(-1.0, 0.0, -10.0),
           r: 2,
           albedo: vec3(0.0, 1.0, 0.0)),

    Sphere(o: point(5.0, 0.0, -15.0),
           r: 2,
           albedo: vec3(0.5, 0.0, 0.0)),

    Sphere(o: point(0.0, 0.0, -38.0),
           r: 2,
           albedo: vec3(0.25, 0.0, 0.0)),

    Sphere(o: point(6.0, 0.0, -30.0),
           r: 2,
           albedo: vec3(0.0, 0.5, 0.0)),

    Plane(o: point(0.0, -2.0, 0.0),
          n: vec(0.0, 1.0, 0.0),
          albedo: vec3(1.0, 1.0, 1.0))
  ]

  var scene = Scene(
    objects: objects
  )

  var framebuf = newFramebuf(opts.width, opts.height)
  var renderer = initRenderer(numActiveWorkers = 6, poolSize = 8)

  renderer.waitForReady()
  discard renderer.start()

  let numLines = opts.height
  for i in 0..<numLines:
    let msg = WorkMsg(scene: scene.addr, opts: opts,
                      framebuf: framebuf.addr, line: i)
    renderer.queueWork(msg)

  var
    numResponses = 0
    lastProgress = NegInf
    tStart = epochTime()
    tCurr = 0.0
    stats = Stats()

  while numResponses < numLines:
    let (available, response) = renderer.tryRecvResult()
    if (available):
      inc numResponses
      stats += response.stats

      let currProgress = numResponses / numLines
      if currProgress - lastProgress > 0.01:
        tCurr = epochTime() - tStart
        let
          tEstTotal = tCurr / currProgress
          tRemaining = tEstTotal - tCurr

        printProgress(currProgress, tCurr, tRemaining)
        printStats(stats)
        lastProgress = currProgress

        setCursorXPos(stdout, 0)
        cursorUp(stdout, 6)

  tCurr = epochTime() - tStart
  printProgress(1.0, tCurr, 0)
  printStats(stats)

  echo "\nRendering completed in " & tCurr | (1, 4) & " seconds"

  renderer.waitForReady()
  discard renderer.shutdown()

  renderer.waitForReady()
  discard renderer.close()

  discard framebuf.writePpm("render.ppm", 8)


main()

