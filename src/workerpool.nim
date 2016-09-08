import cpuinfo, locks, os

import concurrency/semaphore
import concurrency/sharedchannel


template trace(s: string) =
  when defined(DEBUG):
    echo s
  else:
    discard

type
  WorkerCommand = enum
    wcStop, wcStart, wcShutdown

  WorkerState* = enum wsStopped, wsRunning, wsShutdown

  WorkerEventKind* = enum
    wekInitialised, wekStarted, wekStopped, wekNumWorkersChanged,
    wekResetCompleted, wekShutdownCompleted

  WorkerEvent* = ref WorkerEventObj

  WorkerEventObj = object
    case kind*: WorkerEventKind
    of wekInitialised: discard
    of wekStarted: discard
    of wekStopped: discard
    of wekNumWorkersChanged:
      fromNumWorkers*, toNumWorkers*: Natural
    of wekResetCompleted: discard
    of wekShutdownCompleted: discard

  WorkQueueChannel[W] = SharedChannel[W]
  ResultQueueChannel[R] = SharedChannel[R]
  CmdChannel = SharedChannel[WorkerCommand]

  WorkerPool*[W, R] = object
    workers: seq[Worker[W, R]]
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChannels: seq[CmdChannel]
    workProc: proc (msg: W): R
    eventCb: proc (ev: WorkerEvent)
    numActiveWorkers: Natural
    ackCounter: Natural
    semaphores: seq[Semaphore]
    ready: bool
    state: WorkerState
    nextState: WorkerState
    nextEvent: WorkerEvent

  WorkerArgs[W, R] = object
    workerId: Natural
    workProc: proc (msg: W): R
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    cmdChan: CmdChannel
    ackCounter: ptr Natural
    ackProc: proc ()
    workerPool: ptr WorkerPool[W, R]
    monitor: ptr Semaphore

  Worker[W, R] = Thread[WorkerArgs[W, R]]


proc threadProc[W, R](args: WorkerArgs[W, R]) {.thread.} =
  proc workerId(): string = "[" & $args.workerId & "]"

  proc ack() =
    atomicDec(args.ackCounter[])
    assert args.ackCounter[] >= 0
    if args.ackCounter[] == 0:
      args.ackProc()

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
      let (msgAvailable, msg) = args.workQueue[].tryRecv()
      if msgAvailable:
        trace workerId() & " Work message received:\t" #& $msg

        let response = args.workProc(msg)

        trace workerId() & " Sending response:\t\t\t" & $response
        args.resultQueue[].send(response)
        # TODO notify client
 
      let (cmdAvailable, cmd) = args.cmdChan[].tryRecv()
      if cmdAvailable:
        case cmd
        of wcStop:     state = wsStopped;  ack()
        of wcShutdown: state = wsShutdown; ack()
        else: discard
      else:
        trace workerId() &  " Waiting for messages..."
        args.monitor[].await()

    of wsShutdown:
      trace workerId() & " Shutting down"
      return


proc sendEvent*[W, R](wp: var WorkerPool[W, R]) =
  if wp.eventCb != nil:
    wp.eventCb(wp.nextEvent)


proc ackProc*[W, R](wp: var WorkerPool[W, R]) =
  wp.state = wp.nextState
  wp.ready = true
  trace "ackProc, state: " & $wp.state
  wp.sendEvent()


proc poolSize*[W, R](wp: var WorkerPool[W, R]): Natural =
  result = wp.workers.len()

proc numActiveWorkers*[W, R](wp: var WorkerPool[W, R]): Natural =
  result = wp.numActiveWorkers

proc state*[W, R](wp: var WorkerPool[W, R]): WorkerState =
  result = wp.state


proc isReady*[W, R](wp: var WorkerPool[W, R]): bool =
  result = wp.ready


proc waitForReady*[W, R](wp: var WorkerPool[W, R], timeout: Natural = 1) =
  trace "Waiting for ready..."
  while not wp.isReady():
    sleep(timeout)
  trace "  Ready"


proc initWorkerPool*[W, R](
    workProc: proc (msg: W): R,
    poolSize: Natural = 0,
    numActiveWorkers: Natural = 0,
    eventCb: proc (ev: WorkerEvent) = nil): WorkerPool[W, R] =

  trace "Initialising worker pool..."

  var numProcessors = countProcessors()
  trace "  " & $numProcessors & " CPU cores found"

  var nMax = if poolSize == 0: numProcessors else: poolSize
  var n = if numActiveWorkers == 0: nMax else: numActiveWorkers
  if n > nMax: n = nMax

  trace "  Setting pool size to " & $nMax & " worker threads"
  trace "  Setting number of initially active workers to " & $n

  result.workProc = workProc
  result.eventCb = eventCb
  result.numActiveWorkers = n

  result.ackCounter = nMax
  result.ready = false
  result.state = wsStopped
  result.nextState = wsStopped
  result.nextEvent = WorkerEvent(kind: wekInitialised)

  result.workQueue = newSharedChannel[W]()
  result.resultQueue = newSharedChannel[R]()

  result.workers = newSeq[Worker[W, R]](nMax)
  result.cmdChannels = newSeq[CmdChannel](nMax)
  result.semaphores = newSeq[Semaphore](nMax)

  # using result in a closure would confuse the compiler
  # must use a pointer here otherwise a copy would be made
  var wp = result.addr
  proc ack() = ackProc(wp[])

  for i in 0..<nMax:
    result.cmdChannels[i] = newSharedChannel[CmdChannel]()
    initSemaphore(result.semaphores[i])

    var args = WorkerArgs[W, R](
      workerId: i,
      workProc: workProc,
      workQueue: result.workQueue,
      resultQueue: result.resultQueue,
      cmdChan: result.cmdChannels[i],
      ackCounter: result.ackCounter.addr,
      ackProc: ack,
      workerPool: result.addr,
      monitor: result.semaphores[i].addr)

    createThread(result.workers[i], threadProc, args)

  result.waitForReady()
  trace "  Init successful"


proc signalWorkers[W, R](wp: var WorkerPool[W, R]) =
  for i in 0..<wp.numActiveWorkers:
    trace "Signalling [" & $i & "]"
    wp.semaphores[i].signal()


proc queueWork*[W, R](wp: var WorkerPool[W, R], msg: W) =
  wp.workQueue[].send(msg)
  wp.signalWorkers()


proc tryRecvResult*[W, R](wp: var WorkerPool[W, R]): (bool, R) =
  result = wp.resultQueue[].tryRecv()


proc sendCmd[W, R](wp: var WorkerPool[W, R], cmd: WorkerCommand,
                   lo, hi: Natural = 0) =
  wp.ackCounter = hi-lo+1
  for i in lo..hi:
    trace "Sending command " & $cmd & " to [" & $i & "]"
    wp.cmdChannels[i][].send(cmd)
  wp.signalWorkers()


proc start*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsStopped and wp.isReady()):
    return false

  trace "Starting workers..."
  wp.nextState = wsRunning
  wp.nextEvent = WorkerEvent(kind: wekStarted)
  wp.ready = false
  wp.sendCmd(wcStart, hi = wp.numActiveWorkers-1)
  result = true


proc stop*[W, R](wp: var WorkerPool[W, R]): bool =
  if not (wp.state == wsRunning and wp.isReady()):
    return false

  trace "Stopping workers..."
  wp.nextState = wsStopped
  wp.nextEvent = WorkerEvent(kind: wekStopped)
  wp.ready = false
  wp.sendCmd(wcStop, hi = wp.numActiveWorkers-1)
  result = true


proc drainChannel[T](ch: SharedChannel[T]) =
  var
    available = true
    msg: T
  while available:
    (available, msg) = ch[].tryRecv()


proc reset*[W, R](wp: var WorkerPool[W, R]): bool =
  if wp.state == wsShutdown or not wp.isReady():
    return false

  trace "Resetting worker pool..."
  wp.nextState = wsStopped
  wp.nextEvent = WorkerEvent(kind: wekResetCompleted)
  wp.ready = false

  let wasStopped = wp.state == wsStopped

  if wp.state == wsRunning:
    trace "  Stopping workers..."
    wp.sendCmd(wcStop, hi = wp.numActiveWorkers-1)
    wp.waitForReady()

  drainChannel(wp.workQueue)
  drainChannel(wp.resultQueue)

  for i in 0..<wp.numWActiveorkers:
    drainChannel(wp.cmdChannels[i][])

  # Need to send the event manually if we were in stopped state already
  if wasStopped:
    wp.sendEvent()

  trace "  Reset successful"
  result = true


proc setNumWorkers*[W, R](wp: var WorkerPool[W, R],
                          newNumWorkers: Natural): bool =

  if newNumWorkers == wp.numActiveWorkers or
     newNumWorkers > wp.poolSize or
     wp.state == wsShutdown or not wp.isReady():
    return false

  trace "Setting number of workers to " & $newNumWorkers & "..."

  wp.nextEvent = WorkerEvent(kind: wekNumWorkersChanged,
                             fromNumWorkers: wp.numActiveWorkers,
                             toNumWorkers: newNumWorkers)

  let wasStopped = wp.state == wsStopped

  if wp.state == wsRunning:
    wp.ready = false
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

  # Need to send the event manually if we were in stopped state already
  if wasStopped:
    wp.sendEvent()

  wp.numActiveWorkers = newNumWorkers
  result = true


proc shutdown*[W, R](wp: var WorkerPool[W, R]): bool =
  if not wp.isReady():
    return false

  trace "Shutting down all worker threads"
  wp.nextState = wsShutdown
  wp.nextEvent = WorkerEvent(kind: wekShutdownCompleted)
  wp.ready = false
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

