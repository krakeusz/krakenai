class PersistentStorageWorker
{
  constructor()
  {
    table =
    {
      unusableIndustries = {},
      cloggedIndustries = {}
    }
  }

  function _Save();
  function _Load(version, data);

  function _LoadUnusableIndustries();
  function _SaveUnusableIndustries(tab);
  function _LoadCloggedIndustries();
  function _SaveCloggedIndustries(tab);

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

function PersistentStorageWorker::_LoadCloggedIndustries()
{
  if (!(table.rawin("cloggedIndustries")))
  {
    table.cloggedIndustries = {}
  }
  return table.cloggedIndustries;
}

function PersistentStorageWorker::_SaveCloggedIndustries(tab)
{
  table.cloggedIndustries = tab;
}