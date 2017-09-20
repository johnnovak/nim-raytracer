import os
import workerpool2

type
  TileRequest = object
    id: int
    x, y: int
    width, height: int

  TileResponse = object
    id: int

proc processTile(req: TileRequest): TileResponse =
  echo "*** processTile " & $req.id
  result = TileResponse(id: req.id)

var wp: WorkerPool[TileRequest, TileResponse]


while true:
  echo "init()"
  echo wp.init(processTile, workerWaitIntervalMs = 300)
  echo "setNumActiveWorkers()"
  echo wp.setNumActiveWorkers(10)

  echo "start()"
  echo wp.start()
  sleep(1000)

  echo "publish requests"
  echo wp.queueWork(TileRequest(id: 1, x: 0,   y: 0, width: 64, height: 64))
  echo wp.queueWork(TileRequest(id: 2, x: 64,  y: 0, width: 64, height: 64))
  echo wp.queueWork(TileRequest(id: 3, x: 128, y: 0, width: 64, height: 64))
  echo wp.queueWork(TileRequest(id: 4, x: 128, y: 0, width: 64, height: 64))
  echo wp.queueWork(TileRequest(id: 5, x: 192, y: 0, width: 64, height: 64))
  echo wp.queueWork(TileRequest(id: 6, x: 256, y: 0, width: 64, height: 64))
  sleep(1000)

  var ok = true
  var resp: TileResponse
  while ok:
    (ok, resp) = wp.tryRecvResponse()
    if ok:
      echo "MAIN recv: " & $resp

  echo "stop()"
  echo wp.stop()
  sleep(1000)

  echo "shutdown()"
  echo wp.shutdown()
  sleep(1000)

  echo "deinit()"
  echo wp.deinit()
  sleep(1000)
  echo ""


