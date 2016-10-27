import math, terminal, times
import glm

import loaders/obj
import renderer/renderer
import utils/progress


when not defined(SINGLE_THREADED):
  import concurrency/workerpool

  type
    WorkMsg* = object
      scene*: ptr Scene
      opts*: Options
      framebuf*: ptr Framebuf
      line*: Natural
      step*: Natural
      maxStep*: Natural

  type
    ResponseMsg* = object
      stats*: Stats

  proc render(msg: WorkMsg): ResponseMsg =
    let step = if msg.step == 0: 1 else: msg.step
    let maxStep = if msg.maxStep == 0: 1 else: msg.maxStep

    let stats = renderLine(msg.scene[], msg.opts, msg.framebuf[], msg.line,
                           step, maxStep)

    result = ResponseMsg(stats: stats)


  proc initRenderWorkers(numActiveWorkers: Natural = 0,
                   poolSize: Natural = 0): WorkerPool[WorkMsg, ResponseMsg] =

    result = initWorkerPool[WorkMsg, ResponseMsg](render, numActiveWorkers,
                                                  poolSize)


proc main() =
  let opts = Options(
#    width: 1200,
#    height: 800,
#    antialias: Antialias(kind: akMultiJittered, gridSize: 4),
    width: 150,
    height: 100,
    antialias: Antialias(kind: akNone),
    bias: 0.00000001,
    maxRayDepth: 5
  )

  include data/scenes/mesh-bunny.nim

  var framebuf = newFramebuf(opts.width, opts.height)
  let numLines = opts.height
  initRenderer()

  when not defined(SINGLE_THREADED):
    var renderer = initRenderWorkers()
    echo "Using " & $renderer.numActiveWorkers & " CPU cores\n"

    renderer.waitForReady()
    discard renderer.start()

    for i in 0..<numLines:
      let msg = WorkMsg(scene: scene.addr, opts: opts,
                        framebuf: framebuf.addr, line: i)
      renderer.queueWork(msg)

  var
    numResponses = 0
    lastProgress = NegInf
    tStart = epochTime()
    tCurr = 0.0
    totalStats = Stats()

  while numResponses < numLines:
    var
      available: bool
      stats: Stats

    when defined(SINGLE_THREADED):
      let line = numResponses
      stats = renderLine(scene, opts, framebuf, line)
      available = true
    else:
      var response: ResponseMsg
      (available, response) = renderer.tryRecvResult()
      stats = response.stats

    if (available):
      inc numResponses
      totalStats += stats

      let currProgress = numResponses / numLines
      if currProgress - lastProgress > 0.01:
        tCurr = epochTime() - tStart
        let
          tEstTotal = tCurr / currProgress
          tRemaining = tEstTotal - tCurr

        printProgress(currProgress, tCurr, tRemaining)
        printStats(totalStats)
        lastProgress = currProgress

        setCursorXPos(stdout, 0)
        cursorUp(stdout, 6)

  tCurr = epochTime() - tStart
  printProgress(1.0, tCurr, 0)
  printStats(totalStats)

  when not defined(SINGLE_THREADED):
    renderer.waitForReady()
    discard renderer.shutdown()

    renderer.waitForReady()
    discard renderer.close()

  printCompleted(tCurr)

  discard framebuf.writePpm("render.ppm", 8, sRGB = true)


main()

