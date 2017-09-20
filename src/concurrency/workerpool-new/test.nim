import os, times, unittest
import workerpool


const
  NumIterations = 3
  ProcessNopDelayMs = 200
  ProcessDelayMs = 10

  TileWidth = 32
  TileHeight = 32
  FramebufWidth  = TileWidth * 10   # must be a multiple of TileWidth
  FramebufHeight = TileHeight * 10  # must be a multiple of TileHeight

type
  TileRequest = object
    id: int
    x, y: int
    width, height: int
    framebuf: ptr seq[int]

  TileResponse = object
    id: int

  TestWorkerPool = WorkerPool[TileRequest, TileResponse]


proc processRequestNop(req: TileRequest): TileResponse =
  result = TileResponse(id: req.id)

proc processRequestNopDelay(req: TileRequest): TileResponse =
  sleep(ProcessNopDelayMs)
  result = TileResponse(id: req.id)

proc processRequest(req: TileRequest): TileResponse =
  for x in req.x..<(req.x + req.width):
    for y in req.y..<(req.y + req.height):
      let i = y * FramebufWidth + x
      req.framebuf[i] = i
  sleep(ProcessDelayMs)
  result = TileResponse(id: req.id)

proc waitForState(wp: var TestWorkerPool, state: PoolState,
                  timeoutSecs: float = 10) =
  let t1 = epochTime()
  while true:
    if wp.state() == state:
      checkpoint($state & " state entered")
      break
    else:
      sleep(10)
      if epochTime() - t1 > timeoutSecs:
        checkpoint("waitForState " & $state & " timed out")
        fail()

proc newFramebuf(): seq[int] =
  newSeq[int](FramebufWidth * FramebufHeight)

proc checkFramebuf(fb: seq[int]) =
  for i,v in fb.pairs():
    check i == v


suite "WorkerPool":

  test "Idle state transitions (immediate shutdown)":
    var wp: TestWorkerPool

    let req = TileRequest()

    for i in 1..NumIterations:
      checkpoint("Starting iteration " & $i)

      # state = psUninitialised
      check wp.start() == false
      check wp.stop() == false
      check wp.shutdown() == false
      check wp.deinit() == false

      check wp.queueWork(req) == false
      check wp.setNumActiveWorkers(1) == false
      var (responseReceived, resp) = wp.tryRecvResponse()
      check responseReceived == false

      check wp.init(processRequestNop) == true
      waitForState(wp, psStopped)

      # state = psStopped
      check wp.init(processRequestNop) == false
      check wp.stop() == false
      check wp.deinit() == false

      check wp.shutdown() == true
      waitForState(wp, psShutdown)

      # state = psShutdown
      check wp.init(processRequestNop) == false
      check wp.start() == false
      check wp.stop() == false
      check wp.shutdown() == false

      check wp.queueWork(req) == false
      check wp.setNumActiveWorkers(1) == false

      check wp.deinit() == true
      waitForState(wp, psUninitialised)


  test "Idle state transitions (start, stop then shutdown)":
    var wp: TestWorkerPool

    let req = TileRequest()

    for i in 1..NumIterations:
      checkpoint("Starting iteration " & $i)

      # state = psUninitialised
      check wp.start() == false
      check wp.stop() == false
      check wp.shutdown() == false
      check wp.deinit() == false

      check wp.queueWork(req) == false
      check wp.setNumActiveWorkers(1) == false
      var (responseReceived, resp) = wp.tryRecvResponse()
      check responseReceived == false

      check wp.init(processRequestNop) == true
      waitForState(wp, psStopped)

      # state = psStopped
      check wp.init(processRequestNop) == false
      check wp.stop() == false
      check wp.deinit() == false

      check wp.setNumActiveWorkers(1) == true

      check wp.start() == true
      waitForState(wp, psStarted)

      # state = psStarted
      check wp.init(processRequestNop) == false
      check wp.start() == false
      check wp.deinit() == false

      check wp.setNumActiveWorkers(1) == true

      check wp.stop() == true
      waitForState(wp, psStopped)

      # state = psStopped
      check wp.init(processRequestNop) == false
      check wp.stop() == false
      check wp.deinit() == false

      check wp.setNumActiveWorkers(1) == true

      check wp.shutdown() == true
      waitForState(wp, psShutdown)

      # state = psShutdown
      check wp.init(processRequestNop) == false
      check wp.start() == false
      check wp.stop() == false
      check wp.shutdown() == false

      check wp.queueWork(req) == false
      check wp.setNumActiveWorkers(1) == false

      check wp.deinit() == true
      waitForState(wp, psUninitialised)


  test "psStopping state transition":
    var wp: TestWorkerPool

    let req = TileRequest()

    for i in 1..NumIterations:
      checkpoint("Starting iteration " & $i)

      # state = psUninitialised
      check wp.init(processRequestNopDelay) == true
      waitForState(wp, psStopped)

      # state = psStopped
      check wp.start() == true
      waitForState(wp, psStarted)

      for i in 1..10:
        check wp.queueWork(req) == true

      # state = psStarted
      check wp.stop() == true

      # we can check this because the worker proc sleeps for a while
      check wp.state() == psStopping

      waitForState(wp, psStopped)

      # state = psStopped
      check wp.shutdown() == true
      waitForState(wp, psShutdown)

      # state = psShutdown
      check wp.deinit() == true
      waitForState(wp, psUninitialised)


  test "Simple processing test":
    var
      wp: TestWorkerPool
      framebuf = newFramebuf()

    for i in 1..NumIterations:
      checkpoint("Starting iteration " & $i)

      check wp.init(processRequest) == true
      waitForState(wp, psStopped)

      var id = 1
      for x in 0..<int(FramebufWidth / TileWidth):
        for y in 0..<int(FramebufHeight / TileHeight):
          let req = TileRequest(
            id: id,
            x: x * TileWidth,
            y: y * TileHeight,
            width: TileWidth,
            height: TileHeight,
            framebuf: framebuf.addr
          )
          check wp.queueWork(req) == true
          id += 1

      let numTiles = id - 1

      check wp.start() == true
      waitForState(wp, psStarted)

      var numReceived = 0
      while numReceived != numTiles:
        var (responseReceived, response) = wp.tryRecvResponse()
        if responseReceived:
          numReceived += 1
        else:
          sleep(100)

      checkFramebuf(framebuf)

      check wp.shutdown() == true
      waitForState(wp, psShutdown)

      check wp.deinit() == true
      waitForState(wp, psUninitialised)

