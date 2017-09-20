var
  chan: Channel[int]
  thread: Thread[ptr Channel[int]]

proc threadProc(ch: ptr Channel[int]) {.thread.} =
  for i in 0..9:
    ch[].send(1)
  echo "threadProc exit"

while true:
#  chan = Channel[int]()   # WORKAROUND

  echo "open channel"
  chan.open()

  echo "create thread"
  createThread(thread, threadProc, chan.addr)

  joinThread(thread)
  echo "close channel"
  chan.close()
  echo ""
