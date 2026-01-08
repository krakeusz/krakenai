require("../containers/BinaryRelation.nut");

class PersistentStorageWorker
{
  constructor()
  {
    table =
    {
      unusableIndustries = {}, // industryId -> true if the industry is unusable
      cloggedIndustries = {}, // industryId -> timestamp when it got clogged
      industryStations = {}, // industryId -> array of our stationIds that are servicing it. Public API uses BinaryRelation as a wrapper.
    }
  }

  function _Save();
  function _Load(version, data);

  function _LoadUnusableIndustries();
  function _SaveUnusableIndustries(tab);
  function _LoadCloggedIndustries();
  function _SaveCloggedIndustries(tab);
  function _LoadIndustryStations();
  function _SaveIndustryStations(tab);

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

function PersistentStorageWorker::_LoadIndustryStations()
{
  if (!(table.rawin("industryStations")))
  {
    table.industryStations = {}
  }
  return BinaryRelation(table.industryStations);
}

function PersistentStorageWorker::_SaveIndustryStations(tab)
{
  table.industryStations = tab.getData();
}