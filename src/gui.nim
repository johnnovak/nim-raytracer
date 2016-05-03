import math, os, strutils, terminal, times

import glm
import glfw, glfw/wrapper as glfwWrapper
import nanovg

import glad/gl
import image, format, renderer


proc keyCb(win: Win, key: Key, scanCode: int, action: KeyAction,
           modKeys: ModifierKeySet) =

  if action != kaDown: return
  case key
  of keyEscape: win.shouldClose = true
  else: return


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
    width: 1600,
    height: 1200,
    fov: 50.0,
    cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                            .translate(vec3(1.0, 4.0, -3.0)),
    antialias: Antialias(kind: akGrid, gridSize: 32),
    bgColor: vec3(0.3, 0.5, 0.7)
  )

  let objects = @[
    Sphere(o: vec3(-5.0, 0.0, -15.0),
           r: 2,
           color: vec3(0.9, 0.3, 0.2)),

    Sphere(o: vec3(-1.0, 0.0, -10.0),
           r: 2,
           color: vec3(0.3, 0.9, 0.2)),

    Sphere(o: vec3(5.0, 0.0, -15.0),
           r: 2,
           color: vec3(0.2, 0.3, 0.9)),

    Sphere(o: vec3(0.0, 0.0, -38.0),
           r: 2,
           color: vec3(0.9, 0.8, 0.2)),

    Sphere(o: vec3(6.0, 0.0, -30.0),
           r: 2,
           color: vec3(0.6, 0.5, 0.9)),

    Plane(o: vec3(0.0, -2.0, 0.0),
          n: vec3(0.0, 1.0, 0.0),
          color: vec3(1.0, 1.0, 1.0))
  ]

  var scene = Scene(
    objects: objects
  )


  glfw.init()

  var win = newGlWin(
    dim = (w: opts.width, h: opts.height),
    title = "",
    resizable = true,
    bits = (8, 8, 8, 8, 8, 16),
    nMultiSamples = 4,
    version = glv32,
    forwardCompat = true,
    profile = glpCore
  )

  win.keyCb = keyCb
  glfw.makeContextCurrent(win)

  var vg = nvgInit(getProcAddress)
  if vg == nil:
    quit "Error creating NanoVG context"

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  glfw.swapInterval(1)


  var framebuf = newFramebuf(opts.width, opts.height)
  var renderer = initRenderer(numActiveWorkers = 6, poolSize = 8)

  renderer.waitForReady()
  discard renderer.start()

  proc calcTotalRequests(lines, maxStep: Natural): Natural =
    result = 0
    var s = maxStep
    while s > 0:
      result += lines div s
      s = s shr 1

  proc queueMessages(step, maxStep: Natural): Natural =
    result = 0
    for i in countup(0, opts.height-1, step):
      let msg = WorkMsg(scene: scene.addr, opts: opts,
                        framebuf: framebuf.addr,
                        line: i, step: step, maxStep: maxStep)
      renderer.queueWork(msg)
      inc result

  var
    numResponses = 0
    numTotalResponses = 0
    lastProgress = NegInf
    tStart = epochTime()
    tCurr = 0.0
    stats = Stats()
    renderFinished = false

  var img = initImageRGBA(opts.width, opts.height)
  var imgHandle = vg.createImageRGBA(cint(img.w), cint(img.h), 0, img.caddr)

  let maxStep = 32
  var step = maxStep
  var numRequests = queueMessages(step, maxStep)

  let numTotalRequests = calcTotalRequests(opts.height, maxStep)

  while not win.shouldClose:
    var
      (mx, my) = win.cursorPos()
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufSize
      pxRatio = float(fbWidth) / float(winWidth)

    if not renderFinished:
      if numResponses < numRequests:
        while true:
          let (available, response) = renderer.tryRecvResult()
          if available:
            inc numResponses
            inc numTotalResponses
            stats += response.stats

            let currProgress = numTotalResponses / numTotalRequests
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
          else:
            break
      else:
        if step > 1:
          step = step shr 1
          numRequests = queueMessages(step, maxStep)
          numResponses = 0
        else:
          tCurr = epochTime() - tStart
          printProgress(1.0, tCurr, 0)
          printStats(stats)

          echo "\nRendering completed in " & tCurr | (1, 4) & " seconds"
          renderFinished = true

          discard framebuf.writePpm("render.ppm", 8)
          echo "Image file 'render.ppm' written to disk."

          # TODO
          echo numTotalResponses
          echo numTotalRequests


    glViewport(GLint(0), GLint(0), GLsizei(fbWidth), GLsizei(fbHeight))

    glClearColor(0.0, 0.0, 0.0, 0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth, winHeight, pxRatio)

    img.copyFrom(framebuf)
    vg.updateImage(imgHandle, img.caddr)

    var imgPaint = vg.imagePattern(0, 0, cfloat(img.w), cfloat(img.h), 0,
                                   imgHandle, 1.0)
    vg.beginPath()
    vg.rect(0, 0, cfloat(img.w), cfloat(img.h))
    vg.fillPaint(imgPaint)
    vg.fill()

    vg.endFrame()

    glfw.swapBufs(win)
    glfw.pollEvents()


  nvgDelete(vg)
  quit 0

  #TODO
  renderer.waitForReady()
  discard renderer.shutdown()

  renderer.waitForReady()
  discard renderer.close()



main()

