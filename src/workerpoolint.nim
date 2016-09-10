type
  WorkerState* = enum
    wsStopped, wsRunning, wsShutdown

  WorkerPool*[W, R] = object


proc initWorkerPool*[W, R](workProc: proc (msg: W): R,
                           numActiveWorkers: Natural = 0,
                           poolSize: Natural = 0): WorkerPool[W, R]

proc queueWork*[W, R](wp: var WorkerPool[W, R], msg: W)

proc tryRecvResult*[W, R](wp: var WorkerPool[W, R]): (bool, R)



proc poolSize*[W, R](wp: var WorkerPool[W, R]): Natural

proc numActiveWorkers*[W, R](wp: var WorkerPool[W, R]): Natural

proc state*[W, R](wp: var WorkerPool[W, R]): WorkerState

proc isReady*[W, R](wp: var WorkerPool[W, R]): bool



proc start*[W, R](wp: var WorkerPool[W, R]): bool

proc waitForReady*[W, R](wp: var WorkerPool[W, R])


proc stop*[W, R](wp: var WorkerPool[W, R]): bool

proc reset*[W, R](wp: var WorkerPool[W, R]): bool

proc setNumWorkers*[W, R](wp: var WorkerPool[W, R],
                          newNumWorkers: Natural): bool

proc shutdown*[W, R](wp: var WorkerPool[W, R]): bool

proc close*[W, R](wp: var WorkerPool[W, R]): bool

