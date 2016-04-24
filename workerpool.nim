import cpuinfo

template trace(s: string) =
  when defined(DEBUG):
    echo s


type
  WorkerCommand = enum
    wcStart, wcPause, wcStop

  WorkQueueChannel[W] = Channel[W]
  ResultQueueChannel[R] = Channel[R]
  CommandChannel = Channel[WorkerCommand]

  WorkerArgs[W, R] = tuple[workerId: int,
                           workProc: proc (msg: W): R,
                           workQueue: ptr WorkQueueChannel[W],
                           resultQueue: ptr ResultQueueChannel[R],
                           commandChan: ptr CommandChannel]

  Worker[W, R] = Thread[WorkerArgs[W, R]]

  WorkerPool*[W, R] = object
    numWorkers: int
    workers: seq[Worker[W, R]]
    workQueue: WorkQueueChannel[W]
    resultQueue: ResultQueueChannel[R]
    commandChannels: seq[CommandChannel]


proc doWork[W, R](t: WorkerArgs[W, R]) {.thread.} =
  t.commandChan[].open()

  while true:
    cpuRelax()

    let (cmdAvailable, cmd) = t.commandChan[].tryRecv()
    if cmdAvailable:
      case cmd:
      of wcStart: discard   # TODO
      of wcPause: discard   # TODO
      of wcStop:
#        trace "[" & $t.workerId & "]" & " Stop command received, shutting down"
#       TODO fully consume queue?
        return

    let (msgAvailable, msg) = t.workQueue[].tryRecv()
    if msgAvailable:
#      trace "[" & $t.workerId & "]" & " Work message received:   " & $msg

      let response = t.workProc(msg)

#      trace "[" & $t.workerId & "]" & " Sending response:        " & $response
      t.resultQueue[].send(response)


proc createCommandChannels[W, R](w: var WorkerPool[W, R]) =
  w.commandChannels = newSeq[CommandChannel](w.numWorkers)

  for i in 0..<w.numWorkers:
    w.commandChannels[i] = CommandChannel()


proc createWorkers[W, R](w: var WorkerPool[W, R], workProc: proc (msg: W): R) =
  w.workers = newSeq[Worker[W, R]](w.numWorkers)

  for i in 0..<w.numWorkers:
    let workerId = i
    var args = (workerId, workProc, w.workQueue.addr, w.resultQueue.addr,
                w.commandChannels[i].addr)

    createThread(w.workers[i], doWork, args)


proc initWorkerPool*[W, R](workProc: proc (msg: W): R,
                           numWorkers: Natural = 0): WorkerPool[W, R] =

#  trace "Initialising worker pool..."
#  trace "  " & $countProcessors() & " CPU cores found"

  var n = if numWorkers == 0: countProcessors() else: numWorkers
#  trace "  Using " & $numWorkers & " worker threads"

  result.numWorkers = n
  result.workQueue.open()
  result.resultQueue.open()

  result.createCommandChannels()
  result.createWorkers(workProc)

#  trace "  Init successful"


proc close*[W, R](w: var WorkerPool[W, R]) =
#  trace "Shutting down worker pool..."

  for i in 0..<w.numWorkers:
    w.commandChannels[i].send(wcStop)

  joinThreads(w.workers)

  w.workQueue.close()
  w.resultQueue.close()
  for i in 0..<w.numWorkers:
    w.commandChannels[i].close()

#  trace "  Shutdown successful"



proc queueWork*[W, R](w: var WorkerPool[W, R], msg: W) =
  w.workQueue.send(msg)

proc receiveResult*[W, R](w: var WorkerPool[W, R]): (bool, R) =
  result = w.resultQueue.tryRecv()

