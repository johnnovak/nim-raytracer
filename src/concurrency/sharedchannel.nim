type SharedChannel*[T] = ptr Channel[T]

proc newSharedChannel*[T](): SharedChannel[T] =
  result = cast[SharedChannel[T]](allocShared0(sizeof(Channel[T])))
  open(result[])

proc close*[T](ch: var SharedChannel[T]) =
  close(ch[])
  deallocShared(ch)
  ch = nil


