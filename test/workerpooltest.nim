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


suite "stuff":

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
    checkpoint("started -> shutdown OK")


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


  # TODO
  test "state transitions from shutdown state while idle (events)":
    discard


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


  # TODO
  test "changing the number of active workers while idle (events)":
    discard


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
          check wp.setNumWorkers(max(wp.numActiveWorkers / 2, 1).int) == true

        if numResponses == 200:
          wp.waitForReady()
          check wp.setNumWorkers(max(wp.numActiveWorkers / 2, 1).int) == true

        if numResponses == 300:
          wp.waitForReady()
          check wp.setNumWorkers(8) == true

        inc numResponses

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  # TODO
  test "changing the number of active workers while running (events)":
    discard


  # TODO
  test "reset (polling)":
    discard


  # TODO
  test "reset (events)":
    discard


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

