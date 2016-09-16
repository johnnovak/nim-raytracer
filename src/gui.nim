import math, os, strutils, terminal, times

import glm
import glfw, glfw/wrapper as glfwWrapper
import nanovg

import glad/gl
import utils/image
import utils/format
import ui/ui
import renderer/renderer


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
    width: 900,
    height: 600,
    fov: 50.0,
    cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                            .translate(vec3(1.0, 4.0, -3.0)),
    antialias: Antialias(kind: akGrid, gridSize: 16),
    bgColor: vec3(0.3, 0.5, 0.7)
  )

  let objects = @[
    Sphere(o: point(-5.0, 0.0, -15.0),
           r: 2,
           color: vec3(0.9, 0.3, 0.2)),

    Sphere(o: point(-1.0, 0.0, -10.0),
           r: 2,
           color: vec3(0.3, 0.9, 0.2)),

    Sphere(o: point(5.0, 0.0, -15.0),
           r: 2,
           color: vec3(0.2, 0.3, 0.9)),

    Sphere(o: point(0.0, 0.0, -38.0),
           r: 2,
           color: vec3(0.9, 0.8, 0.2)),

    Sphere(o: point(6.0, 0.0, -30.0),
           r: 2,
           color: vec3(0.6, 0.5, 0.9)),

    Plane(o: point(0.0, -2.0, 0.0),
          n: vec3(0.0, 1.0, 0.0),
          color: vec3(1.0, 1.0, 1.0))
  ]

  var scene = Scene(
    objects: objects
  )

  var
    doRedraw = false
    windowWidth, windowHeight: int

  proc draw()

  proc winRefreshCb(win: Win) =
    draw()
    glfw.swapBufs(win)
    doRedraw = false


  proc reshape(win: Win, res: tuple[w, h: int]) =
    windowWidth  = res.w
    windowHeight = if res.h > 0: res.h else: 1
    doRedraw = true

  proc cursorPosCb(win: Win, pos: tuple[x, y: float64]) =
    doRedraw = true

  proc mouseBtnCb(win: Win, btn: MouseBtn, pressed: bool,
                  modKeys: ModifierKeySet) =
    doRedraw = true


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
  win.cursorPosCb = cursorPosCb
  win.mouseBtnCb = mouseBtnCb
  win.framebufSizeCb = reshape
  win.winRefreshCb = winRefreshCb

  glfw.makeContextCurrent(win)

  var vg = nvgInit(getProcAddress)
  if vg == nil:
    quit "Error creating NanoVG context"

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  glfw.swapInterval(1)

  setUIContext(vg)
  if not initUI():
    quit "Error initialising UI"

  var framebuf = newFramebuf(opts.width, opts.height)

  var renderer = initRenderer(numActiveWorkers = 6, poolSize = 8)
  renderer.waitForReady()

  var img = initImageRGBA(opts.width, opts.height)
  var imgHandle = vg.createImageRGBA(cint(img.w), cint(img.h), 0, img.caddr)


  proc calcTotalRequests(lines, maxStep: Natural): Natural =
    assert isPowerOfTwo(maxStep)
    result = 0
    var s = maxStep
    while s > 0:
      result += ceil(lines / s).int
      s = s div 2

  proc queueRequests(step, maxStep: Natural): Natural =
    assert isPowerOfTwo(step)
    assert isPowerOfTwo(maxStep)
    result = 0
    for i in countup(0, opts.height-1, step):
      let msg = WorkMsg(scene: scene.addr, opts: opts,
                        framebuf: framebuf.addr,
                        line: i, step: step, maxStep: maxStep)
      renderer.queueWork(msg)
      inc result


  proc beginFrame() =
    var
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufSize
      pxRatio = float(fbWidth) / float(winWidth)

    glViewport(GLint(0), GLint(0), GLsizei(fbWidth), GLsizei(fbHeight))

    glClearColor(0.0, 0.0, 0.0, 0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth, winHeight, pxRatio)


  proc drawImage() =
    img.copyFrom(framebuf)
    vg.updateImage(imgHandle, img.caddr)

    let 
      x = (windowWidth - img.w) / 2
      y = (windowHeight - img.h) / 2

    var imgPaint = vg.imagePattern(x, y, cfloat(img.w), cfloat(img.h), 0,
                                   imgHandle, 1.0)
    vg.beginPath()
    vg.rect(x, y, cfloat(img.w), cfloat(img.h))
    vg.fillPaint(imgPaint)
    vg.fill()


  let maxStep = 32

  var
    step = maxStep
    numResponses = 0
    numTotalResponses = 0
    renderFinished = false

  var numRequests = queueRequests(step, maxStep)
  let numTotalRequests = calcTotalRequests(opts.height, maxStep)

  var
    currProgress: float
    lastProgress = NegInf
    tStart = 0.0
    tCurr = 0.0
    tRemaining = 0.0
    stats = Stats()

  proc updateProgress() =
    currProgress = numTotalResponses / numTotalRequests
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


  proc printFinalProgress() =
    tCurr = epochTime() - tStart
    printProgress(1.0, tCurr, 0)
    printStats(stats)

    echo "\nRendering completed in " & tCurr | (1, 4) & " seconds"


  proc handleUI() =
    let (mx, my) = win.cursorPos()
    beginUI(mx, my,
            mbLeftDown = win.mouseBtnDown(mbLeft),
            mbRightDown = win.mouseBtnDown(mbRight))

    panel(1, 0, 0, 210, 200)

    if button(2, 10, 15, 60, 18, "Start",
              disabled = not renderer.isReady() or
                             renderer.state() == wsRunning):
      discard renderer.start()
      tStart = epochTime()

    if button(3, 77, 15, 60, 18, "Stop",
              disabled = not renderer.isReady() or
                             renderer.state() == wsStopped):
      discard renderer.stop()

    progressBar(10, 45, 190, 16, currProgress)

    label(10, 70, 100, 18, "Ellapsed time:", halign = haLeft)
    label(10, 70, 190, 18, formatDuration(tCurr), halign = haRight)

    label(10, 88, 200, 18, "Remaining time:", halign = haLeft)
    label(10, 88, 190, 18, formatDuration(tRemaining), halign = haRight)

    var text = "Meanwhile, an immediate mode GUI is one in which the GUI system generally does not retain information about your GUI, but instead, repeatedly asks you to re-specify what your controls are, and where they are, and so on.\n\nTesting\nthis\nmiserable piece of shit\n\nfor i in 0..1:\n  for j in 0..2:\n    echo $i & $j"
    console(0, windowHeight.float - 250, windowWidth.float, 250, text)


  proc draw() =
    beginFrame()
    drawImage()
    handleUI()
    handleUI()
    vg.endFrame()


  let (fbWidth, fbHeight) = win.framebufSize
  win.reshape((w: fbWidth, h: fbHeight))

  while not win.shouldClose:
    if not renderFinished:
      if numResponses < numRequests:
        while true:
          let (available, response) = renderer.tryRecvResult()
          if available:
            inc numResponses
            inc numTotalResponses
            stats += response.stats
            updateProgress()
            doRedraw = true
          else:
            break
      else:
        if step > 1:
          step = step div 2
          numRequests = queueRequests(step, maxStep)
          numResponses = 0
        else:
          printFinalProgress()
          renderFinished = true
          doRedraw = true
          discard renderer.stop()

          discard framebuf.writePpm("render.ppm", 8)
          echo "Image file 'render.ppm' written to disk."

    if doRedraw:
      winRefreshCb(win)

    glfw.swapBufs(win)
    glfw.pollEvents()


  nvgDelete(vg)

  renderer.waitForReady()
  discard renderer.shutdown()

  renderer.waitForReady()
  discard renderer.close()

main()

