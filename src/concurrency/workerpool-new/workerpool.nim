import cpuinfo, os

type
  Command = enum
    cmdStart, cmdStop, cmdShutdown

  WorkerState = enum
    wsStopped, wsStarted, wsShutDown

  PoolState* = enum
    psUninitialised, psStopped, psStarted, psShutDown
    # transitional states
    psStopping, psStarting, psSettingNumActiveWorkers, psShuttingDown

  WorkProc[W, R] = proc (req: W): R

  WorkerArgs[W, R] = object
    id: int
    commandChannel: ptr Channel[Command]
    ackChannel: ptr Channel[int]
    requestChannel: ptr Channel[W]
    responseChannel: ptr Channel[R]
    workProc: WorkProc[W, R]
    waitIntervalMs: int

  WorkerThread[W, R] = Thread[WorkerArgs[W, R]]

  WorkerPool*[W, R] = object
    workerThreads: seq[WorkerThread[W, R]]
    numActiveWorkers: int
    workerWaitIntervalMs: int

    poolState: PoolState
    workerStates: seq[WorkerState]

    requestChannel: Channel[W]
    responseChannel: Channel[R]

    commandChannels: seq[Channel[Command]]
    ackChannel: Channel[int]
    ack: seq[int]
    expectedAckFirst, expectedAckLast: int


proc threadProc[W, R](args: WorkerArgs[W, R]) {.thread, gcsafe.} =
  var state = wsStopped

  proc changeState(newState: WorkerState) =
#    echo "# changeState, id: " & $args.id & ", state: " & $newState
    state = newState
    args.ackChannel[].send(args.id)

  while true:
    case state
    of wsStopped:
      var cmd = args.commandChannel[].recv()
      if   cmd == cmdStart:    changeState(wsStarted)
      elif cmd == cmdShutdown: changeState(wsShutDown)

    of wsStarted:
      var (cmdReceived, cmd) = args.commandChannel[].tryRecv()
      if cmdReceived:
        if   cmd == cmdStop:     changeState(wsStopped)
        elif cmd == cmdShutdown: changeState(wsShutDown)
      else:
        var (reqReceived, req) = args.requestChannel[].tryRecv()
        if reqReceived:
#          echo "*** " & $args.id & " recv: " & $req
          let response = args.workProc(req)
          args.responseChannel[].send(response)
        else:
#          echo "*** " & $args.id & " wait"
          sleep(args.waitIntervalMs)

    of wsShutDown:
      return


proc receiveAck[W, R](wp: var WorkerPool[W, R]) =
  var ok = true
  var id: int
  while ok:
    (ok, id) = wp.ackChannel.tryRecv()
    if ok:
#      echo("ACK " & $id & " received")
      wp.ack[id] += 1

proc checkAck[W, R](wp: var WorkerPool[W, R]): bool =
  for i in 0..(wp.expectedAckFirst - 1):
    assert wp.ack[i] == 0
  for i in (wp.expectedAckLast + 1)..wp.ack.high:
    assert wp.ack[i] == 0
  for i in wp.expectedAckFirst..wp.expectedAckLast:
    assert wp.ack[i] < 2
    if wp.ack[i] == 0:
      return false
  result = true

proc updatePoolState[W, R](wp: var WorkerPool[W, R]) =
  wp.receiveAck()
  if wp.poolState == psStarting:
    if wp.checkAck(): wp.poolState = psStarted
  elif wp.poolState == psStopping:
    if wp.checkAck(): wp.poolState = psStopped
  elif wp.poolState == psSettingNumActiveWorkers:
    if wp.checkAck(): wp.poolState = psStarted
  elif wp.poolState == psShuttingDown:
    if wp.checkAck(): wp.poolState = psShutDown

proc clearWorkerAck[W, R](wp: var WorkerPool[W, R]) =
  for i in 0..wp.ack.high:
    wp.ack[i] = 0

proc sendCommand[W, R](wp: var WorkerPool[W, R], cmd: Command, first: int, last: int) =
  wp.clearWorkerAck()
  for i in first..last:
    wp.commandChannels[i].send(cmd)
  wp.expectedAckFirst = first
  wp.expectedAckLast = last


proc init*[W, R](wp: var WorkerPool[W, R],
                 workProc: WorkProc[W, R],
                 poolSize: int = countProcessors(),
                 workerWaitIntervalMs = 50): bool =

  if wp.poolState == psUninitialised:
    wp.workerThreads = newSeq[WorkerThread[W, R]](poolSize)
    wp.ack = newSeq[int](poolSize)
    wp.commandChannels = newSeq[Channel[Command]](poolSize)

    # Seems like re-opening already closed channels result in a segfault,
    # hence this
    wp.requestChannel = Channel[W]()
    wp.responseChannel = Channel[R]()
    wp.ackChannel = Channel[int]()

    wp.requestChannel.open()
    wp.responseChannel.open()
    wp.ackChannel.open()

    wp.poolState = psStopped
    wp.numActiveWorkers = poolSize
    wp.workerWaitIntervalMs = workerWaitIntervalMs

    for i in 0..wp.workerThreads.high:
      wp.commandChannels[i].open()
      var args = WorkerArgs[W, R](
        id: i,
        commandChannel: wp.commandChannels[i].addr,
        ackChannel: wp.ackChannel.addr,
        requestChannel: wp.requestChannel.addr,
        responseChannel: wp.responseChannel.addr,
        workProc: workProc,
        waitIntervalMs: wp.workerWaitIntervalMs
      )
      createThread(wp.workerThreads[i], threadProc, args)

    result = true
  else:
    result = false


proc deinit*[W, R](wp: var WorkerPool[W, R]): bool =
  wp.updatePoolState()
  if wp.poolState == psShutDown:
    joinThreads(wp.workerThreads)

    wp.requestChannel.close()
    wp.responseChannel.close()
    wp.ackChannel.close()

    for i in 0..wp.workerThreads.high:
      wp.commandChannels[i].close()

    wp.workerThreads = nil
    wp.ack = nil
    wp.commandChannels = nil
    wp.numActiveWorkers = 0

    wp.poolState = psUninitialised

    result = true
  else:
    result = false


proc start*[W, R](wp: var WorkerPool[W, R]): bool =
  wp.updatePoolState()
  if wp.poolState == psStopped:
    wp.sendCommand(cmdStart, first = 0, last = wp.numActiveWorkers - 1)
    wp.poolState = psStarting
    result = true
  else:
    result = false

proc stop*[W, R](wp: var WorkerPool[W, R]): bool =
  wp.updatePoolState()
  if wp.poolState == psStarted:
    wp.sendCommand(cmdStop, first = 0, last = wp.numActiveWorkers - 1)
    wp.poolState = psStopping
    result = true
  else:
    result = false

proc shutdown*[W, R](wp: var WorkerPool[W, R]): bool =
  wp.updatePoolState()
  if wp.poolState == psStopped or wp.poolState == psStarted:
    wp.sendCommand(cmdShutdown, first = 0, last = wp.workerThreads.len - 1 )
    wp.poolState = psShuttingDown
    result = true
  else:
    result = false

proc state*[W, R](wp: var WorkerPool[W, R]): PoolState =
  wp.updatePoolState()
  result = wp.poolState


proc setNumActiveWorkers*[W, R](wp: var WorkerPool[W, R], n: int): bool = 
  if n < 1 or n > wp.workerThreads.len:
    return false

  wp.updatePoolState()
  if wp.poolState == psStopped:
    wp.numActiveWorkers = n
    result = true
  elif wp.poolState == psStarted:
    if n == wp.numActiveWorkers:
      discard
    elif n > wp.numActiveWorkers:
      wp.sendCommand(cmdStart, first = wp.numActiveWorkers, last = n - 1)
    else:
      wp.sendCommand(cmdStop, first = n, last = wp.numActiveWorkers - 1)
    wp.poolState = psSettingNumActiveWorkers
    result = true
  else:
    result = false


proc queueWork*[W, R](wp: var WorkerPool[W, R], workRequest: W): bool =
  wp.updatePoolState()
  if wp.poolState != psUninitialised and
     wp.poolState != psShuttingDown and
     wp.poolState != psShutdown:
    wp.requestChannel.send(workRequest)
    result = true
  else:
    result = false

proc tryRecvResponse*[W, R](wp: var WorkerPool[W, R]): (bool, R) =
  wp.updatePoolState()
  if wp.poolState != psUninitialised:
    result = wp.responseChannel.tryRecv()
  else:
    var response: R
    result = (false, response)

