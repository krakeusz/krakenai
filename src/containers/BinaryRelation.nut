
class BinaryRelation {
  
  constructor(data = null) {
    if (data != null) {
      _data = data;
    }
  }
  _data = {};
}

function BinaryRelation::addRelation(a, b) {
  if (!(a in _data))
  {
    _data[a] <- [];
  }
  _data[a].push(b);
}

function BinaryRelation::getRelations(a) {
  return (a in _data) ? _data[a] : [];
}

function BinaryRelation::getData() {
  return _data;
}

function BinaryRelation::removeRelationsTo(b) {
  foreach (a, bs in _data) {
    local new_bs = [];
    foreach (item in bs) {
      if (item != b) {
        new_bs.push(item);
      }
    }
    _data[a] = new_bs;
  }
}