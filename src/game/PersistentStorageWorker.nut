class PersistentStorageWorker
{
  constructor()
  {
    table =
    {
      unusableIndustries = {}
    }
  }

  function _Save();
  function _Load(version, data);

  function _LoadUnusableIndustries();
  function _SaveUnusableIndustries(tab);

  table = null;
}

function PersistentStorageWorker::_Save()
{
  return table;
}

function PersistentStorageWorker::_Load(version, data)
{
  table = data;
  if (!(table.rawin("unusableIndustries")))
  {
    table.unusableIndustries = {}
  }
}

function PersistentStorageWorker::_LoadUnusableIndustries()
{
  return table.unusableIndustries;
}

function PersistentStorageWorker::_SaveUnusableIndustries(tab)
{
  table.unusableIndustries = tab;
}
