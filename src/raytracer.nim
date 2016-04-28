import math, strutils, terminal, times
import glm
import format, renderer


proc formatStats(s: Stats): string =
  let percHits = s.numIntersectionHits / s.numIntersectionTests * 100
  result =   "numPrimaryRays:       " & $s.numPrimaryRays | 16 &
           "\nnumIntersectionTests: " & $s.numIntersectionTests | 16 &
           "\nnumIntersectionHits:  " & $s.numIntersectionHits | 16 &
           " (" & percHits | (1, 2) & "% of total tests)"


proc printProgressBar(p: float) =
  const maxlen = 68
  let
    barlen = int(p * maxlen)
    currprog = $int(p * 100) | 4 & "%"

  let bar = if barlen == 0: "" else:
            repeat('=', max(barlen-1, 0)) & ">"

  echo "[" & bar & spaces(max(maxlen-barlen, 0)) & "]" & currprog


proc printProgress(p, tcurr, tremaining: float) =
  printProgressBar(p)
  echo "Ellapsed time: " & formatDuration(tcurr) &
       "\t\tRemaining time: " & formatDuration(tremaining)

proc printStats(stats: Stats) =
  echo "\n" & formatStats(stats)


proc main() =
  let opts = Options(
    width: 1920,
    height: 1080,
    fov: 50.0,
    # TODO
    cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0)),
    antialias: Antialias(kind: akGrid, gridSize: 4),
    bgColor: color(0.3, 0.5, 0.7)
  )

  var objects = @[
    Sphere(o: vec3(-5.0, 0.0, -15.0),
           r: 2,
           color: color(0.9, 0.3, 0.2)),

    Sphere(o: vec3(-1.0, 0.0, -10.0),
           r: 2,
           color: color(0.3, 0.9, 0.2)),

    Sphere(o: vec3(5.0, 0.0, -15.0),
           r: 2,
           color: color(0.2, 0.3, 0.9)),

    Sphere(o: vec3(0.0, 0.0, -38.0),
           r: 2,
           color: color(0.9, 0.8, 0.2)),

    Sphere(o: vec3(6.0, 0.0, -30.0),
           r: 2,
           color: color(0.6, 0.5, 0.9)),

    Plane(o: vec3(0.0, -2.0, 0.0),
          n: vec3(0.0, 1.0, 0.0),
          color: color(1.0, 1.0, 1.0))
  ]

  var scene = Scene(
    objects: objects
  )

  var img = newImage(opts.width, opts.height)

  var wp = initRenderer()
  let numLines = opts.height

  wp.run()

  for i in 0..<numLines:
    let msg = WorkMsg(scene: scene.addr, opts: opts, img: img.addr, line: i)
    wp.queueWork(msg)

  var
    numResponses = 0
    lastProgress = NegInf
    tstart = epochTime()
    tcurr = 0.0
    stats = Stats()

  while numResponses < numLines:
    cpuRelax()
    var (available, response) = wp.receiveResult()
    if (available):
      inc numResponses
      stats += response.stats

      var currProgress = numResponses / numLines
      if currProgress - lastProgress > 0.01:
        tcurr = epochTime() - tstart
        var tremaining = tcurr

        printProgress(currProgress, tcurr, tremaining)
        printStats(stats)
        lastProgress = currProgress

        setCursorXPos(stdout, 0)
        cursorUp(stdout, 6)

  tcurr = epochTime() - tstart
  printProgress(1.0, tcurr, 0)
  printStats(stats)

  echo "\nRendering completed in " & tcurr | (1, 4) & " s"

  wp.close()

  discard img.writePpm("render.ppm", 8)


main()
