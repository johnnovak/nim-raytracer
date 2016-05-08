import cpuinfo

template trace(s: string) =
  when defined(DEBUG):
    echo s
  else:
    discard


type SharedChannel[T] = ptr Channel[T]

proc newSharedChannel[T](): SharedChannel[T] =
  result = cast[SharedChannel[T]](allocShared0(sizeof(Channel[T])))
  open(result[])

proc close[T](ch: var SharedChannel[T]) =
  close(ch[])
  deallocShared(ch)
  ch = nil


type
  WorkerCommand = enum
    wcStop, wcStart, wcShutdown

  WorkerState* = enum
    wsStopped, wsRunning, wsShutdown

  WorkQueueChannel[W] = SharedChannel[W]
  ResultQueueChannel[R] = SharedChannel[R]
  CmdChannel = SharedChannel[WorkerCommand]
  AckChannel = SharedChannel[bool]

  WorkerArgs[W, R] = object
    workerId: Natural
    workProc: proc (msg: W): R
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChan: CmdChannel
    ackChan: AckChannel

  Worker[W, R] = Thread[WorkerArgs[W, R]]

  WorkerPool*[W, R] = object
    workers: seq[Worker[W, R]]
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChannels: seq[CmdChannel]
    ackChannels: seq[AckChannel]
    workProc: proc (msg: W): R
    numActiveWorkers: Natural
    ackCounter: Natural
    state: WorkerState


proc doWork[W, R](args: WorkerArgs[W, R]) {.thread.} =
  proc sendAck() = args.ackChan[].send(true)

  proc workerId(): string = "[" & $args.workerId & "]"

  trace workerId() & " Starting"
  sendAck()
  var state = wsStopped

  while true:
    case state
    of wsStopped:
      let cmd = args.cmdChan[].recv()
      case cmd
      of wcStart:    state = wsRunning; sendAck()
      of wcShutdown: state = wsShutdown
      else: discard

    of wsRunning:
      let (cmdAvailable, cmd) = args.cmdChan[].tryRecv()
      if cmdAvailable:
        case cmd
        of wcStop:     state = wsStopped; sendAck(); continue
        of wcShutdown: state = wsShutdown; continue
        else: discard

      let (msgAvailable, msg) = args.workQueue[].tryRecv()
      if msgAvailable:
        trace workerId() & " Work message received:\t" #& $msg

        let response = args.workProc(msg)

        trace workerId() & " Sending response:\t\t\t" & $response
        args.resultQueue[].send(response)
      else:
        cpuRelax()

    of wsShutdown:
      trace workerId() & " Shutting down"
      sendAck()
      return


proc poolSize*[W, R](wp: var WorkerPool[W, R]): Natural =
  result = wp.workers.len()

proc numActiveWorkers*[W, R](wp: var WorkerPool[W, R]): Natural =
  result = wp.numActiveWorkers

proc state*[W, R](wp: var WorkerPool[W, R]): WorkerState =
  result = wp.state


proc isReady*[W, R](wp: var WorkerPool[W, R]): bool =
  if wp.ackCounter > 0:
    trace "Waiting for " & $wp.ackCounter & " ack signals"

    for i in 0..<wp.poolSize():
      let (available, _) = wp.ackChannels[i][].tryRecv()
      if available:
        trace "  Ack received from worker " & $i
        dec wp.ackCounter

  result = wp.ackCounter == 0


proc waitForReady*[W, R](wp: var WorkerPool[W, R]) =
  while not wp.isReady():
    cpuRelax()


proc initWorkerPool*[W, R](workProc: proc (msg: W): R,
                           numActiveWorkers: Natural = 0,
                           poolSize: Natural = 0): WorkerPool[W, R] =

  trace "Initialising worker pool..."

  var numProcessors = countProcessors()
  trace "  " & $numProcessors & " CPUs found"

  var    n = if numActiveWorkers == 0: numProcessors else: numActiveWorkers
  var nMax = if poolSize == 0: numProcessors else: poolSize
  if n > nMax: nMax = n

  trace "  Setting pool size to " & $nMax & " worker threads"
  trace "  Setting initial pool size to " & $n & " worker threads"

  result.workProc = workProc
  result.numActiveWorkers = numActiveWorkers
  result.ackCounter = nMax
  result.state = wsStopped

  result.workQueue = newSharedChannel[W]()
  result.resultQueue = newSharedChannel[R]()

  result.workers = newSeq[Worker[W, R]](nMax)
  result.cmdChannels = newSeq[CmdChannel](nMax)
  result.ackChannels = newSeq[AckChannel](nMax)

  for i in 0..<nMax:
    result.cmdChannels[i] = newSharedChannel[CmdChannel]()
    result.ackChannels[i] = newSharedChannel[AckChannel]()

    var args = WorkerArgs[W, R](
      workerId: i,
      workProc: workProc,
      workQueue: result.workQueue,
      resultQueue: result.resultQueue,
      cmdChan: result.cmdChannels[i],
      ackChan: result.ackChannels[i])

    createThread(result.workers[i], doWork, args)

  trace "  Init successful"


proc queueWork*[W, R](wp: var WorkerPool[W, R], msg: W) =
  wp.workQueue[].send(msg)


proc tryRecvResult*[W, R](wp: var WorkerPool[W, R]): (bool, R) =
  result = wp.resultQueue[].tryRecv()


proc sendCmd[W, R](wp: var WorkerPool[W, R], cmd: WorkerCommand,
                   lo, hi: Natural = 0) =
  for i in lo..hi:
    wp.cmdChannels[i][].send(cmd)
  wp.ackCounter = hi-lo+1


proc start*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsStopped and wp.isReady()):
    return false

  trace "Sending start command to all active workers"
  wp.sendCmd(wcStart, hi = wp.numActiveWorkers-1)
  wp.state = wsRunning
  result = true


proc stop*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsRunning and wp.isReady()):
    return false

  trace "Sending stop command to all active workers"
  wp.sendCmd(wcStop, hi = wp.numActiveWorkers-1)
  wp.state = wsStopped
  result = true


proc drainChannel[T](ch: SharedChannel[T]) =
  var
    available = true
    msg: T
  while available:
    (available, msg) = ch[].tryRecv()


proc reset*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsStopped and wp.isReady()):
    return false

  trace "Resetting worker pool..."
  drainChannel(wp.workQueue)
  drainChannel(wp.resultQueue)

  for i in 0..<wp.numWActiveorkers:
    drainChannel(wp.cmdChannels[i][])
    drainChannel(wp.ackChannels[i][])

  trace "Reset successful"
  result = true


proc setNumWorkers*[W, R](wp: var WorkerPool[W, R],
                          newNumWorkers: Natural): bool =

  if newNumWorkers == wp.numActiveWorkers or
     wp.state == wsShutdown or not wp.isReady():
    return false

  trace "Setting number of workers to " & $newNumWorkers

  if wp.state == wsRunning:
    if newNumWorkers > wp.numActiveWorkers:
      let
        lo = wp.numActiveWorkers
        hi = newNumWorkers-1
      trace "  Starting workers " & $lo & " to " & $hi
      wp.sendCmd(wcStart, lo, hi)

    else:
      let
        lo = newNumWorkers
        hi = wp.numActiveWorkers-1
      trace "  Stopping workers " & $lo & " to " & $hi
      wp.sendCmd(wcStop, lo, hi)

  wp.numActiveWorkers = newNumWorkers
  result = true


proc shutdown*[W, R](wp: var WorkerPool[W, R]): bool =
  if not wp.isReady():
    return false

  trace "Shutting down all worker threads"
  wp.sendCmd(wcShutdown, hi = wp.poolSize-1)
  result = true


proc close*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsShutdown and wp.isReady()):
    return false

  trace "Closing queues"
  wp.workQueue.close()
  wp.resultQueue.close()

  for i in 0..<wp.poolSize:
    wp.cmdChannels[i].close()
    wp.ackChannels[i].close()

