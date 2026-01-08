class PersistentStorageProxy
{
  _worker = null;
}

class PersistentStorage
{
  static function Save(); // should be called by main only
  static function Load(version, data); // should be called by main only
  static function LoadUnusableIndustries();
  static function SaveUnusableIndustries();
  static function LoadCloggedIndustries();
  static function SaveCloggedIndustries();
  static function LoadIndustryStations();
  static function SaveIndustryStations();
  static _proxy = PersistentStorageProxy();
}

function PersistentStorage::Save()
{
  return PersistentStorage._proxy._worker._Save();
}

function PersistentStorage::Load(version, data)
{
  PersistentStorage._proxy._worker._Load(version, data);
}

function PersistentStorage::LoadUnusableIndustries()
{
  return PersistentStorage._proxy._worker._LoadUnusableIndustries();
}

function PersistentStorage::SaveUnusableIndustries(tab)
{
  return PersistentStorage._proxy._worker._SaveUnusableIndustries(tab);
}

function PersistentStorage::LoadCloggedIndustries()
{
  return PersistentStorage._proxy._worker._LoadCloggedIndustries();
}

function PersistentStorage::SaveCloggedIndustries(tab)
{
  return PersistentStorage._proxy._worker._SaveCloggedIndustries(tab);
}

function PersistentStorage::LoadIndustryStations()
{
  return PersistentStorage._proxy._worker._LoadIndustryStations();
}

function PersistentStorage::SaveIndustryStations(tab)
{
  return PersistentStorage._proxy._worker._SaveIndustryStations(tab);
}
