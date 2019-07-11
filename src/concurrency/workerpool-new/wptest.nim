import cpuinfo, os
import strformat


type
  MessageKind = enum
    mkCommand
    mkRequest

  Command = enum
    cmdStart, cmdStop, cmdShutdown

  Request = object
    x, y, w, h: float

  Message[R] = object
    case kind: MessageKind
    of mkCommand: cmd: Command
    of mkRequest: req: R


var ch: Channel[Message[Request]]



proc threadProc(args: int) {.thread.} =
  while true:
    var msg = ch.recv()
    case msg.kind:
    of mkCommand: echo fmt"Received command: {msg.cmd}"
    of mkRequest: echo fmt"Received request: {msg.req}"


ch = Channel[Message[Request]]()
ch.open()

var th: Thread[int]
createThread(th, threadProc, 5)

ch.send(Message[Request](kind: mkCommand, cmd: cmdStart))
ch.send(Message[Request](kind: mkCommand, cmd: cmdStop))
ch.send(Message[Request](kind: mkCommand, cmd: cmdShutdown))
sleep(1000)

ch.send(Message[Request](kind: mkRequest, req: Request(x: 1, y: 2, w: 320, h: 200)))
sleep(1000)

joinThread(th)

