import cpuinfo, locks, os


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


type Monitor = ptr object
  L: Lock
  C: Cond

proc newMonitor(): Monitor =
  result = cast[Monitor](allocShared0(sizeof(Monitor)))
  initLock(result.L)
  initCond(result.C)

proc destroyMonitor(m: Monitor) =
  deinitCond(m[].C)
  deinitLock(m[].L)


type
  WorkerCommand = enum
    wcStop, wcStart, wcShutdown

  WorkerState* = enum
    wsStopped, wsRunning, wsShutdown

  WorkQueueChannel[W] = SharedChannel[W]
  ResultQueueChannel[R] = SharedChannel[R]
  CmdChannel = SharedChannel[WorkerCommand]

  WorkerArgs[W, R] = object
    workerId: Natural
    workProc: proc (msg: W): R
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChan: CmdChannel
    ackCounter: ptr Natural
    monitor: Monitor

  Worker[W, R] = Thread[WorkerArgs[W, R]]

  WorkerPool*[W, R] = object
    workers: seq[Worker[W, R]]
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChannels: seq[CmdChannel]
    workProc: proc (msg: W): R
    numActiveWorkers: Natural
    ackCounter: Natural
    monitors: seq[Monitor]
    state: WorkerState


proc doWork[W, R](args: WorkerArgs[W, R]) {.thread.} =
  proc workerId(): string = "[" & $args.workerId & "]"

  proc ack() =
    atomicDec(args.ackCounter[])
    assert args.ackCounter[] >= 0
    if args.ackCounter[] == 0:
      discard  # state change notification

  trace workerId() & " Starting"
  var state = wsStopped
  ack()

  while true:
    case state
    of wsStopped:
      let cmd = args.cmdChan[].recv()
      case cmd
      of wcStart:    state = wsRunning;  ack()
      of wcShutdown: state = wsShutdown; ack()
      else: discard

    of wsRunning:
      let (cmdAvailable, cmd) = args.cmdChan[].tryRecv()
      if cmdAvailable:
        case cmd
        of wcStop:     state = wsStopped;  ack()
        of wcShutdown: state = wsShutdown; ack()
        else: discard

      let (msgAvailable, msg) = args.workQueue[].tryRecv()
      if msgAvailable:
        trace workerId() & " Work message received:\t" #& $msg

        let response = args.workProc(msg)

        trace workerId() & " Sending response:\t\t\t" & $response
        args.resultQueue[].send(response)
        # TODO notify client
      else:
        wait(args.monitor[].C, args.monitor[].L)
        trace workerId() &  " Waiting for messages"
        trace workerId() &  " " & $state

    of wsShutdown:
      trace workerId() & " Shutting down"
      return


proc poolSize*[W, R](wp: var WorkerPool[W, R]): Natural =
  result = wp.workers.len()

proc numActiveWorkers*[W, R](wp: var WorkerPool[W, R]): Natural =
  result = wp.numActiveWorkers

proc state*[W, R](wp: var WorkerPool[W, R]): WorkerState =
  result = wp.state


proc isReady*[W, R](wp: var WorkerPool[W, R]): bool =
  result = wp.ackCounter == 0


proc waitForReady*[W, R](wp: var WorkerPool[W, R]) =
  trace "Waiting for ready..."
  while not wp.isReady():
    cpuRelax()


proc initWorkerPool*[W, R](workProc: proc (msg: W): R,
                           poolSize: Natural = 0,
                           numActiveWorkers: Natural = 0): WorkerPool[W, R] =

  trace "Initialising worker pool..."

  var numProcessors = countProcessors()
  trace "  " & $numProcessors & " CPU cores found"

  var nMax = if poolSize == 0: numProcessors else: poolSize
  var n = if numActiveWorkers == 0: nMax else: numActiveWorkers
  if n > nMax: n = nMax

  trace "  Setting pool size to " & $nMax & " worker threads"
  trace "  Setting number of initially active workers to " & $n

  result.workProc = workProc
  result.numActiveWorkers = n
  result.ackCounter = nMax
  result.state = wsStopped

  result.workQueue = newSharedChannel[W]()
  result.resultQueue = newSharedChannel[R]()

  result.workers = newSeq[Worker[W, R]](nMax)
  result.cmdChannels = newSeq[CmdChannel](nMax)
  result.monitors = newSeq[Monitor](nMax)

  for i in 0..<nMax:
    result.cmdChannels[i] = newSharedChannel[CmdChannel]()
    result.monitors[i] = newMonitor()

    var args = WorkerArgs[W, R](
      workerId: i,
      workProc: workProc,
      workQueue: result.workQueue,
      resultQueue: result.resultQueue,
      cmdChan: result.cmdChannels[i],
      ackCounter: result.ackCounter.addr,
      monitor: result.monitors[i])

    createThread(result.workers[i], doWork, args)

  result.waitForReady()
  trace "  Init successful"


proc notifyWorkers[W, R](wp: var WorkerPool[W, R]) =
  for i in 0..<wp.numActiveWorkers:
    trace "Signalling [" & $i & "]"
    signal(wp.monitors[i].C)


proc queueWork*[W, R](wp: var WorkerPool[W, R], msg: W) =
  wp.workQueue[].send(msg)
  wp.notifyWorkers()


proc tryRecvResult*[W, R](wp: var WorkerPool[W, R]): (bool, R) =
  result = wp.resultQueue[].tryRecv()


proc sendCmd[W, R](wp: var WorkerPool[W, R], cmd: WorkerCommand,
                   lo, hi: Natural = 0) =
  wp.ackCounter = hi-lo+1
  for i in lo..hi:
    trace "Sending command " & $cmd & " to [" & $i & "]"
    wp.cmdChannels[i][].send(cmd)
  wp.notifyWorkers()


proc start*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsStopped and wp.isReady()):
    return false

  trace "Sending start command to all active workers"
  wp.state = wsRunning
  wp.sendCmd(wcStart, hi = wp.numActiveWorkers-1)
  result = true


proc stop*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsRunning and wp.isReady()):
    return false

  trace "Sending stop command to all active workers"
  wp.state = wsStopped
  wp.sendCmd(wcStop, hi = wp.numActiveWorkers-1)
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

  trace "Reset successful"
  result = true


proc setNumWorkers*[W, R](wp: var WorkerPool[W, R],
                          newNumWorkers: Natural): bool =

  if newNumWorkers == wp.numActiveWorkers or
     newNumWorkers > wp.poolSize or
     wp.state == wsShutdown or not wp.isReady():
    return false

  trace "Setting number of workers to " & $newNumWorkers

  if wp.state == wsRunning:
    if newNumWorkers > wp.numActiveWorkers:
      let
        lo = wp.numActiveWorkers
        hi = newNumWorkers-1
      trace "  Starting [" & $lo & "] to [" & $hi & "]"
      wp.sendCmd(wcStart, lo, hi)

    else:
      let
        lo = newNumWorkers
        hi = wp.numActiveWorkers-1
      trace "  Stopping [" & $lo & "] to [" & $hi & "]"
      wp.sendCmd(wcStop, lo, hi)

  wp.numActiveWorkers = newNumWorkers
  result = true


proc shutdown*[W, R](wp: var WorkerPool[W, R]): bool =
  if not wp.isReady():
    return false

  trace "Shutting down all worker threads"
  wp.state = wsShutdown
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

  result = true

