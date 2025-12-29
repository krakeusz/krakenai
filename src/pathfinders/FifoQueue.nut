class FifoQueue
{
  constructor(maxSize)
  {
    _maxSize = maxSize + 1; // there are maxSize + 1 possible sizes of the queue, so we need one more element in the buffer to represent that
    _buffer = array(_maxSize);
  }

  function Pop();

  function Push(elem);

  function IsFull();

  function IsEmpty();

  function Count();

  static function _Test();

  _first = 0; // elements are stored at indices [_first, _last)
  _last = 0;
  _maxSize = 0;
  _buffer = []; // circular buffer
}

function FifoQueue::IsEmpty()
{
  return _last == _first;
}

function FifoQueue::Count()
{
  return (_last + _maxSize - _first) % _maxSize;
}

function FifoQueue::IsFull()
{
  return Count() == _maxSize - 1;
}

function FifoQueue::Push(elem)
{
  if (IsFull())
  {
    throw "Cannot push to the queue: queue is full";
  }
  _buffer[_last] = elem;
  _last = (_last + 1) % _maxSize;
}

function FifoQueue::Top()
{
  if (IsEmpty())
  {
    throw "Cannot get top queue element: queue is empty";
  }
  return _buffer[_first];
}

function FifoQueue::Pop()
{
  if (IsEmpty())
  {
    throw "Cannot pop from the queue: queue is empty";
  }
  local elem = _buffer[_first];
  _first = (_first + 1) % _maxSize;
  return elem;
}

function FifoQueue::_Test()
{
  local q = FifoQueue(4);
  assert(q.Count() == 0);
  assert(q.IsEmpty());
  q.Push(10);
  q.Push(11);
  assert(q.Count() == 2);
  assert(q.IsEmpty() == false);
  local ten = q.Pop();
  assert(ten == 10);
  assert(q.Count() == 1);
  assert(q.Top() == 11);
  q.Push(12);
  q.Push(13);
  q.Push(14);
  assert(q.Count() == 4);
  try
  {
    q.Push(15);
    assert(false);
  }
  catch(e)
  {
  }
  local eleven = q.Pop();
  assert(eleven == 11);
  AILog.Info("All tests passed!");
}