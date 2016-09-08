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


suite "stuff":

  test "pool autosizing":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)

    check wp.poolSize == countProcessors()
    check wp.numActiveWorkers == wp.poolSize

    wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, numActiveWorkers = 1000)

    check wp.poolSize == countProcessors()
    check wp.numActiveWorkers == wp.poolSize

  test "state transitions from stopped state":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)

    check wp.state == wsStopped
    check wp.stop() == false
    check wp.shutdown() == true

    wp.waitForReady()
    check wp.state == wsShutdown


  test "state transitions from running state":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)
    check wp.start() == true

    wp.waitForReady()
    check wp.state == wsRunning
    check wp.stop() == true

    wp.waitForReady()
    check wp.state == wsStopped
    check wp.start() == true

    wp.waitForReady()
    check wp.state == wsRunning
    check wp.shutdown() == true

    wp.waitForReady()
    check wp.state == wsShutdown


  test "state transitions from shutdown state":
    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)
    check wp.shutdown() == true

    wp.waitForReady()
    check wp.state == wsShutdown
    check wp.start() == false
    check wp.stop() == false
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
    check wp.setNumWorkers(3) == false
    check wp.state == wsShutdown



  test "changing the number of active workers":
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


  test "changing the number of active workers while running":
    if countProcessors() == 1:
      echo "*** WARNING: Cannot execute test on a single-core CPU"
      skip()

    var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork)
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
          check wp.setNumWorkers(countProcessors()) == true

        inc numResponses

    check wp.shutdown() == true
    wp.waitForReady()
    check wp.close() == true


  test "reset":
    discard
