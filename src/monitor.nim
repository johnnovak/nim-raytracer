import os, locks

type
  Msg = object
    mon: ptr Monitor

  Monitor = ptr object
    L: Lock
    C: Cond

var
  thread: Thread[Msg]

proc threadFunc(m: Msg) {.thread.} =
  for i in 0..100:
    echo i
    wait(m.mon[].C, m.mon[].L)

proc newMonitor(): Monitor =
  result = cast[Monitor](allocShared0(sizeof(Monitor)))
  initLock(result.L)
  initCond(result.C)

var m = newMonitor()
var msg = Msg(mon: m.addr)

createThread(thread, threadFunc, msg)

while true:
  sleep(400)
  signal(m.C)

