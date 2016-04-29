import cpuinfo

template trace(s: string) =
  when defined(DEBUG):
    echo s
  else:
    discard


type
  WorkerState = enum
    wsStop, wsRun, wsShutdown

  WorkQueueChannel[W] = Channel[W]
  ResultQueueChannel[R] = Channel[R]
  CmdChannel = Channel[WorkerState]
  AckChannel = Channel[bool]

  WorkerArgs[W, R] = object
    workerId: Natural
    workProc: proc (msg: W): R
    workQueue: ptr WorkQueueChannel[W]
    resultQueue: ptr ResultQueueChannel[R]
    cmdChan: ptr CmdChannel
    ackChan: ptr AckChannel

  Worker[W, R] = Thread[WorkerArgs[W, R]]

  WorkerPool*[W, R] = object
    numWorkers: Natural
    workers: seq[Worker[W, R]]
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChannels: seq[CmdChannel]
    ackChannels: seq[AckChannel]


proc doWork[W, R](a: WorkerArgs[W, R]) {.thread.} =
  var state = wsStop

  while true:
    case state:
    of wsStop:
      let cmd = a.cmdChan[].recv()
      case cmd:
      of wsRun, wsShutdown:
        state = cmd
        a.ackChan[].send(true)
      else: discard

    of wsRun:
      let (cmdAvailable, cmd) = a.cmdChan[].tryRecv()
      if cmdAvailable:
        case cmd:
        of wsStop, wsShutdown:
          state = cmd
          a.ackChan[].send(true)
          continue
        else: discard

      let (msgAvailable, msg) = a.workQueue[].tryRecv()
      if msgAvailable:
        trace "[" & $a.workerId & "]" &
              " Work message received:   "# & $msg

        let response = a.workProc(msg)

        trace "[" & $a.workerId & "]" &
              " Sending response:        " & $response

        a.resultQueue[].send(response)
      else:
        cpuRelax()

    of wsShutdown:
      trace "[" & $a.workerId & "]" & " Shutting down"
      # TODO fully consume queue?
      return


proc createWorkerChannels[W, R](w: var WorkerPool[W, R]) =
  w.cmdChannels = newSeq[CmdChannel](w.numWorkers)
  w.ackChannels = newSeq[AckChannel](w.numWorkers)

  for i in 0..<w.numWorkers:
    var cmd = CmdChannel()
    cmd.open()
    w.cmdChannels[i] = cmd

    var ack = AckChannel()
    ack.open()
    w.ackChannels[i] = ack


proc createWorkers[W, R](w: var WorkerPool[W, R], workProc: proc (msg: W): R) =
  w.workers = newSeq[Worker[W, R]](w.numWorkers)

  for i in 0..<w.numWorkers:
    var args = WorkerArgs[W, R](
      workerId: i,
      workProc: workProc,
      workQueue: w.workQueue.addr,
      resultQueue: w.resultQueue.addr,
      cmdChan: w.cmdChannels[i].addr,
      ackChan: w.ackChannels[i].addr)

    createThread(w.workers[i], doWork, args)


proc initWorkerPool*[W, R](workProc: proc (msg: W): R,
                           numWorkers: Natural = 0): WorkerPool[W, R] =

  trace "Initialising worker pool..."
  trace "  " & $countProcessors() & " CPU cores found"

  var n = if numWorkers == 0: countProcessors() else: numWorkers
  trace "  Using " & $numWorkers & " worker threads"

  result.numWorkers = n
  result.workQueue.open()
  result.resultQueue.open()

  result.createWorkerChannels()
  result.createWorkers(workProc)

  trace "  Init successful"


proc sendCmd[W, R](w: var WorkerPool[W, R], cmd: WorkerState) =
  for i in 0..<w.numWorkers:
    w.cmdChannels[i].send(cmd)

proc waitAck[W, R](w: var WorkerPool[W, R]) =
  var numAck = 0
  while true:
    for i in 0..<w.numWorkers:
      let (available, ack) = w.ackChannels[i].tryRecv()
      if available:
        trace "Ack received from worker " & $i
        inc numAck
        if numAck == w.numWorkers:
          return
      else:
        cpuRelax()

proc run*[W, R](w: var WorkerPool[W, R]) =
  w.sendCmd(wsRun)
  w.waitAck()

proc stop*[W, R](w: var WorkerPool[W, R]) =
  w.sendCmd(wsStop)
  w.waitAck()

proc drainChannel(c: Channel) =
  while true:
    let (available, msg) = c.tryRecv()
    if not available:
      break


proc reset*[W, R](w: var WorkerPool[W, R]) =
  w.stop()
  drainChannel(w.workQueue)
  drainChannel(w.resultQueue)

  for i in 0..<w.numWorkers:
    drainChannel(w.cmdChannels[i])
    drainChannel(w.ackChannels[i])


proc close*[W, R](w: var WorkerPool[W, R]) =
  trace "Shutting down worker pool..."

  w.sendCmd(wsShutdown)
  w.waitAck()

  joinThreads(w.workers)

  w.workQueue.close()
  w.resultQueue.close()
  for i in 0..<w.numWorkers:
    w.cmdChannels[i].close()
    w.ackChannels[i].close()

  trace "  Shutdown successful"


proc queueWork*[W, R](w: var WorkerPool[W, R], msg: W) =
  w.workQueue.send(msg)

proc receiveResult*[W, R](w: var WorkerPool[W, R]): (bool, R) =
  result = w.resultQueue.tryRecv()

