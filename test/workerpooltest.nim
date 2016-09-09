import os
import unittest
import workerpool
import cpuinfo


let
  SLEEP_TIME_MS = 100
  NUM_MESSAGES = 500

type
  WorkMsg = object
    text: string

  ResponseMsg = object
    text: string
    n: int

proc doWork(msg: WorkMsg): ResponseMsg =
  sleep(SLEEP_TIME_MS)
  result = ResponseMsg(text: msg.text & " response", n: msg.text.len())


var
  eventReceived = 1
  event: WorkerEvent = nil

proc eventCb(ev: WorkerEvent) =
  event = ev
  atomicInc(eventReceived)
  assert eventReceived == 1

proc prepareCheckEvent() =
  atomicDec(eventReceived)
  assert eventReceived == 0

proc doCheckEvent(expected: WorkerEvent) =
  while eventReceived != 1:
    discard
  check event.kind == expected.kind

template checkEvent(expectedEvent: WorkerEvent, expectedState: WorkerState,
                    body: stmt) =
  prepareCheckEvent()
  body
  doCheckEvent(expectedEvent)
  check wp.state == expectedState
  check wp.isReady() == true


suite "workerpool test":

  test "pool autosizing":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)

    check wp.poolSize == countProcessors()
    check wp.numActiveWorkers == wp.poolSize

    wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, numActiveWorkers = 1000)

    check wp.poolSize == countProcessors()
    check wp.numActiveWorkers == wp.poolSize


  test "state transitions from stopped state while idle (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)
    check wp.state == wsStopped
    check wp.stop() == false
    check wp.shutdown() == true
    wp.waitForReady()
    check wp.state == wsShutdown


  test "state transitions from stopped state while idle (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    checkpoint("init OK")

    check wp.stop() == false
    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")


  test "state transitions from running state while idle (polling)":
    var  wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                   numActiveWorkers = 4)
    check wp.state == wsStopped
    checkpoint("init OK")

    check wp.start() == true
    wp.waitForReady()
    check wp.state == wsRunning
    checkpoint("stopped -> running OK")

    check wp.stop() == true
    wp.waitForReady()
    check wp.state == wsStopped
    checkpoint("running -> stopped OK")

    check wp.start() == true
    wp.waitForReady()
    check wp.state == wsRunning
    checkpoint("stopped -> running OK")

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.state == wsShutdown
    checkpoint("running -> shutdown OK")


  test "state transitions from running state while idle (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    checkpoint("init OK")

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stopped -> running OK")

    checkEvent(WorkerEvent(kind: wekStopped), wsStopped):
      check wp.stop() == true
    checkpoint("running -> stopped OK")

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stopped -> running OK")

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("running -> shutdown OK")


  test "state transitions from shutdown state while idle (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)
    check wp.shutdown() == true

    wp.waitForReady()
    check wp.state == wsShutdown
    check wp.start() == false
    check wp.stop() == false
    check wp.close() == true


  test "state transitions from shutdown state while idle (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    checkpoint("init OK")

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")
    check wp.start() == false
    check wp.stop() == false
    check wp.close() == true


  test "changing the number of active workers while idle (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.state == wsStopped
    check wp.numActiveWorkers == 4

    check wp.setNumWorkers(3) == true
    wp.waitForReady()
    check wp.numActiveWorkers == 3

    check wp.setNumWorkers(3) == false
    check wp.setNumWorkers(9) == false

    check wp.start() == true
    wp.waitForReady()
    check wp.state == wsRunning
    check wp.setNumWorkers(6) == true
    wp.waitForReady()
    check wp.numActiveWorkers == 6

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.setNumWorkers(3) == false
    check wp.state == wsShutdown


  test "changing the number of active workers while idle (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    checkpoint("init OK")

    checkEvent(WorkerEvent(kind: wekNumWorkersChanged,
                           fromNumWorkers: 4, toNumWorkers: 3), wsStopped):
      check wp.setNumWorkers(3) == true
    checkpoint("setNumWorkers(3) OK")
 
    check wp.setNumWorkers(3) == false
    check wp.setNumWorkers(9) == false

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stopeed -> running OK")

    checkEvent(WorkerEvent(kind: wekNumWorkersChanged,
                           fromNumWorkers: 3, toNumWorkers: 6), wsRunning):
      check wp.setNumWorkers(6) == true
    checkpoint("setNumWorkers(6) OK")

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true

    check wp.setNumWorkers(3) == false

  discard """
Traceback (most recent call last)
workerpool.nim(106)      threadProc
workerpool.nim(76)       ack
workerpool.nim(192)      ack
workerpool.nim(129)      ackProc
workerpool.nim(119)      sendEvent
workerpooltest.nim(31)   eventCb
system.nim(3397)         failedAssertImpl
system.nim(3389)         raiseAssert
system.nim(2532)         sysFatal
Error: unhandled exception: eventReceived == 1  [AssertionError]
Traceback (most recent call last)
workerpool.nim(106)      threadProc
workerpool.nim(76)       ack
workerpool.nim(192)      ack
workerpool.nim(129)      ackProc
workerpool.nim(119)      sendEvent
workerpooltest.nim(31)   eventCb
system.nim(3397)         failedAssertImpl
system.nim(3389)         raiseAssert
system.nim(2532)         sysFatal
Error: unhandled exception: eventReceived == 1  [AssertionError]
Error: execution of an external program failed: '/Users/johnnovak/dev/jn/nim-raytracer/test/workerpooltest '
"""


  test "changing the number of active workers while running (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.start() == true

    for i in 0..<NUM_MESSAGES:
      let msg = WorkMsg(text: $i)
      wp.queueWork(msg)

    var numResponses = 0
    while numResponses != NUM_MESSAGES:
      var (available, response) = wp.tryRecvResult()
      if (available):

        if numResponses == 100:
          wp.waitForReady()
          check wp.setNumWorkers(2) == true

        if numResponses == 200:
          wp.waitForReady()
          check wp.setNumWorkers(1) == true

        if numResponses == 300:
          wp.waitForReady()
          check wp.setNumWorkers(8) == true

        inc numResponses

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  test "changing the number of active workers while running (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    checkpoint("init OK")

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stopped -> running OK")

    for i in 0..<NUM_MESSAGES:
      let msg = WorkMsg(text: $i)
      wp.queueWork(msg)

    var numResponses = 0
    while numResponses != NUM_MESSAGES:
      var (available, response) = wp.tryRecvResult()
      if (available):

        if numResponses == 100:
          checkEvent(WorkerEvent(kind: wekNumWorkersChanged,
                                 fromNumWorkers: 4, toNumWorkers: 2),
                     wsRunning):
            check wp.setNumWorkers(2) == true
          checkpoint("setNumWorkers(2) OK")

        if numResponses == 200:
          checkEvent(WorkerEvent(kind: wekNumWorkersChanged,
                                 fromNumWorkers: 2, toNumWorkers: 1),
                     wsRunning):
            check wp.setNumWorkers(1) == true
          checkpoint("setNumWorkers(1) OK")

        if numResponses == 300:
          checkEvent(WorkerEvent(kind: wekNumWorkersChanged,
                                 fromNumWorkers: 1, toNumWorkers: 8),
                     wsRunning):
            check wp.setNumWorkers(8) == true
          checkpoint("setNumWorkers(8) OK")

        inc numResponses

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")
    check wp.close() == true


  test "reset from stopped state while idle (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.state == wsStopped
    checkpoint("init OK")

    let (available, response) = wp.tryRecvResult()
    check available == false

    check wp.reset() == true
    wp.waitForReady()
    check wp.state == wsStopped
    checkpoint("reset OK")

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  test "reset from stopped state while idle (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    check wp.state == wsStopped
    checkpoint("init OK")

    let (available, response) = wp.tryRecvResult()
    check available == false

    checkEvent(WorkerEvent(kind: wekResetCompleted), wsStopped):
      check wp.reset() == true
    checkpoint("reset OK")

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")
    check wp.close() == true


  test "reset from running state while idle (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.state == wsStopped
    checkpoint("init OK")

    let (available, response) = wp.tryRecvResult()
    check available == false

    check wp.start() == true
    wp.waitForReady()

    check wp.reset() == true
    wp.waitForReady()
    check wp.state == wsStopped
    checkpoint("reset OK")

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  test "reset from running state while idle (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    check wp.state == wsStopped
    checkpoint("init OK")

    let (available, response) = wp.tryRecvResult()
    check available == false

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stoped -> running OK")

    checkEvent(WorkerEvent(kind: wekResetCompleted), wsStopped):
      check wp.reset() == true
    checkpoint("reset OK")

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")
    check wp.close() == true


  test "reset from stopped state when there are messages in the queue (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.state == wsStopped
    checkpoint("init OK")

    for i in 0..<NUM_MESSAGES:
      let msg = WorkMsg(text: $i)
      wp.queueWork(msg)

    var (available, response) = wp.tryRecvResult()
    check available == false

    check wp.reset() == true
    wp.waitForReady()
    check wp.state == wsStopped
    checkpoint("reset OK")

    check wp.start() == true
    wp.waitForReady()

    sleep(SLEEP_TIME_MS * 5)

    (available, response) = wp.tryRecvResult()
    check available == false

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  test "reset from stopped state when there are messages in the queue (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    check wp.state == wsStopped
    checkpoint("init OK")

    for i in 0..<NUM_MESSAGES:
      let msg = WorkMsg(text: $i)
      wp.queueWork(msg)

    var (available, response) = wp.tryRecvResult()
    check available == false

    checkEvent(WorkerEvent(kind: wekResetCompleted), wsStopped):
      check wp.reset() == true
    checkpoint("reset OK")

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stoped -> running OK")

    sleep(SLEEP_TIME_MS * 5)

    (available, response) = wp.tryRecvResult()
    check available == false

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")
    check wp.close() == true


  test "reset from running state while messages are being processed (polling)":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.state == wsStopped
    checkpoint("init OK")

    for i in 0..<NUM_MESSAGES:
      let msg = WorkMsg(text: $i)
      wp.queueWork(msg)

    var (available, response) = wp.tryRecvResult()
    check available == false

    check wp.start() == true
    wp.waitForReady()

    sleep(SLEEP_TIME_MS * 10)

    check wp.reset() == true
    wp.waitForReady()
    check wp.state == wsStopped
    checkpoint("reset OK")

    (available, response) = wp.tryRecvResult()
    check available == false

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  test "reset from running state while messages are being processed (events)":
    var wp: WorkerPool[WorkMsg, ResponseMsg]

    checkEvent(WorkerEvent(kind: wekInitialised), wsStopped):
      wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                numActiveWorkers = 4,
                                                eventCb = eventCb)
    check wp.state == wsStopped
    checkpoint("init OK")

    for i in 0..<NUM_MESSAGES:
      let msg = WorkMsg(text: $i)
      wp.queueWork(msg)

    var (available, response) = wp.tryRecvResult()
    check available == false

    checkEvent(WorkerEvent(kind: wekStarted), wsRunning):
      check wp.start() == true
    checkpoint("stoped -> running OK")

    sleep(SLEEP_TIME_MS * 10)

    checkEvent(WorkerEvent(kind: wekResetCompleted), wsStopped):
      check wp.reset() == true
    checkpoint("reset OK")

    (available, response) = wp.tryRecvResult()
    check available == false

    checkEvent(WorkerEvent(kind: wekShutdownCompleted), wsShutdown):
      check wp.shutdown() == true
    checkpoint("stopped -> shutdown OK")
    check wp.close() == true


  test "closing the pool":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, poolSize = 8,
                                                  numActiveWorkers = 4)

    check wp.state == wsStopped
    check wp.close() == false

    check wp.start() == true
    wp.waitForReady()
    check wp.state == wsRunning
    check wp.close() == false

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.state == wsShutdown

