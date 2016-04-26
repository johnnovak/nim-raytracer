import workerpool, os

type
  WorkMsg = object
    text: string

  ResponseMsg = object
    text: string
    n: int


proc doWork(msg: WorkMsg): ResponseMsg =
  sleep(100)
  result = ResponseMsg(text: msg.text & " response", n: msg.text.len())


var wp = initWorkerPool[WorkMsg, ResponseMsg](doWork, 8)

const numMessages = 500

for i in 0..<numMessages:
  let msg = WorkMsg(text: $i)
  wp.queueWork(msg)

var numResponses = 0
while numResponses != numMessages:
  cpuRelax()
  var (available, response) = wp.receiveResult()
  if (available):
#    echo "Received response:    \t" & $ response
    inc numResponses

wp.close()
