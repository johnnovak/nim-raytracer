import cpuinfo, os

type
  TileRequest = object
    id: int
    x, y: int
    width, height: int

  TileResponse = object
    id: int

type
  Command = enum
    cmdStart, cmdStop, cmdShutdown

  WorkerId = int

  WorkerState = enum
    wsStopped, wsRunning, wsShutDown

  PoolState = enum
    psUninitialised, psStopped, psRunning, psShutDown
    # transitional states
    psStopping, psStarting, psSettingNumActiveWorkers, psShuttingDown

var
  gWorkerThreads: seq[Thread[WorkerId]]
  gNumActiveWorkers: int
  gWorkerWaitIntervalMs: int = 50

  gPoolState: PoolState = psUninitialised
  gWorkerStates: seq[WorkerState]

  gRequestChannel: Channel[TileRequest]
  gResponseChannel: Channel[TileResponse]

  gCommandChannels: seq[Channel[Command]]
  gAckChannel: Channel[WorkerId]
  gAck: seq[int]
  gExpectedAckFirst, gExpectedAckLast: WorkerId


proc processTile(req: TileRequest) =
  echo "*** processTile " & $req.id


proc threadProc(id: WorkerId) {.thread, gcsafe.} =

  proc changeState(newState: WorkerState) =
    gWorkerStates[id] = newState
    gAckChannel.send(id)

  while true:
    case gWorkerStates[id]
    of wsStopped:
      var cmd = gCommandChannels[id].recv()
      if   cmd == cmdStart:    changeState(wsRunning)
      elif cmd == cmdShutdown: changeState(wsShutDown)

    of wsRunning:
      var (cmdReceived, cmd) = gCommandChannels[id].tryRecv()
      if cmdReceived:
        if   cmd == cmdStop:     changeState(wsStopped)
        elif cmd == cmdShutdown: changeState(wsShutDown)
      else:
        var (reqReceived, req) = gRequestChannel.tryRecv()
        if reqReceived:
          echo "*** " & $id & " recv: " & $req
          processTile(req)
          gResponseChannel.send(TileResponse(id: req.id))
        else:
          echo "*** " & $id & " wait"
          sleep(gWorkerWaitIntervalMs)

    of wsShutDown:
      return


proc receiveAck() =
  var ok = true
  var id: int
  while ok:
    (ok, id) = gAckChannel.tryRecv()
    if ok:
      echo("ACK " & $id & " received")
      gAck[id] += 1

proc checkAck(): bool =
  for i in 0..(gExpectedAckFirst - 1):
    assert gAck[i] == 0
  for i in (gExpectedAckLast + 1)..gAck.high:
    assert gAck[i] == 0
  for i in gExpectedAckFirst..gExpectedAckLast:
    assert gAck[i] < 2
    if gAck[i] == 0:
      return false
  result = true

proc updatePoolState() =
  receiveAck()
  if gPoolState == psStarting:
    if checkAck(): gPoolState = psRunning
  elif gPoolState == psStopping:
    if checkAck(): gPoolState = psStopped
  elif gPoolState == psSettingNumActiveWorkers:
    if checkAck(): gPoolState = psRunning
  elif gPoolState == psShuttingDown:
    if checkAck(): gPoolState = psShutDown

proc clearWorkerAck() =
  for i in 0..gAck.high:
    gAck[i] = 0

proc sendCommand(cmd: Command, first: int, last: int) =
  clearWorkerAck()
  for i in first..last:
    gCommandChannels[i].send(cmd)
  gExpectedAckFirst = first
  gExpectedAckLast = last

proc initPool*(poolSize: int): bool =
  if gPoolState == psUninitialised:
    gWorkerThreads = newSeq[Thread[WorkerId]](poolSize)
    gWorkerStates = newSeq[WorkerState](poolSize)
    gAck = newSeq[int](poolSize)
    gCommandChannels = newSeq[Channel[Command]](poolSize)

    gRequestChannel.open()
    gResponseChannel.open()
    gAckChannel.open()

    gPoolState = psStopped
    gNumActiveWorkers = poolSize

    for i in 0..gWorkerThreads.high:
      gWorkerStates[i] = wsStopped
      gCommandChannels[i].open()
      createThread(gWorkerThreads[i], threadProc, i)

    result = true
  else:
    result = false


proc deinitPool*(): bool =
  updatePoolState()
  if gPoolState == psShutDown:
    joinThreads(gWorkerThreads)

    gRequestChannel.close()
    gResponseChannel.close()
    gAckChannel.close()

    for i in 0..gWorkerThreads.high:
      gCommandChannels[i].close()

    gWorkerThreads = nil
    gWorkerStates = nil
    gAck = nil
    gCommandChannels = nil
    gNumActiveWorkers = 0

    gPoolState = psUninitialised

    result = true
  else:
    result = false


proc start*(): bool =
  updatePoolState()
  if gPoolState == psStopped:
    sendCommand(cmdStart, first = 0, last = gNumActiveWorkers - 1)
    gPoolState = psStarting
    result = true
  else:
    result = false

proc stop*(): bool =
  updatePoolState()
  if gPoolState == psRunning:
    sendCommand(cmdStart, first = 0, last = gNumActiveWorkers - 1)
    gPoolState = psStopping
    result = true
  else:
    result = false

proc shutdown*(): bool =
  updatePoolState()
  if gPoolState == psStopped or gPoolState == psRunning:
    sendCommand(cmdStart, first = 0, last = gWorkerThreads.len - 1 )
    gPoolState = psShuttingDown
    result = true
  else:
    result = false

proc state*(): PoolState =
  updatePoolState()
  result = gPoolState


proc setNumActiveWorkers*(n: int): bool = 
  if n < 1 or n > gWorkerThreads.len:
    return false

  updatePoolState()
  if gPoolState == psStopped:
    gNumActiveWorkers = n
    result = true
  elif gPoolState == psRunning:
    if n == gNumActiveWorkers:
      discard
    elif n > gNumActiveWorkers:
      sendCommand(cmdStart, first = gNumActiveWorkers, last = n - 1)
    else:
      sendCommand(cmdStop, first = n, last = gNumActiveWorkers - 1)
    gPoolState = psSettingNumActiveWorkers
    result = true
  else:
    result = false


proc queueWork*(r: TileRequest): bool =
  if gPoolState == psStopped or gPoolState == psRunning:
    gRequestChannel.send(r)
    result = true
  else:
    result = false

proc tryRecvResults*(): (bool, TileResponse) =
  if gPoolState == psStopped or gPoolState == psRunning:
    result = gResponseChannel.tryRecv()
  else:
    var t: TileResponse
    result = (false, t)


echo initPool(countProcessors())
echo "setNumActiveWorkers()"
echo setNumActiveWorkers(10)

echo "start()"
echo  start()
sleep(1000)

echo "publish requests"
discard queueWork(TileRequest(id: 1, x: 0,   y: 0, width: 64, height: 64))
discard queueWork(TileRequest(id: 2, x: 64,  y: 0, width: 64, height: 64))
discard queueWork(TileRequest(id: 3, x: 128, y: 0, width: 64, height: 64))
discard queueWork(TileRequest(id: 4, x: 128, y: 0, width: 64, height: 64))
discard queueWork(TileRequest(id: 5, x: 192, y: 0, width: 64, height: 64))
discard queueWork(TileRequest(id: 6, x: 256, y: 0, width: 64, height: 64))
sleep(1000)

var ok = true
var resp: TileResponse
while ok:
  (ok, resp) = tryRecvResults()
  if ok:
    echo "MAIN recv: " & $resp

echo "stop()"
echo  stop()
sleep(1000)

echo "shutdown()"
echo  shutdown()

