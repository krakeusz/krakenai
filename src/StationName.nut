
class StationName
{
  static function IndustryShortName(industryId);
  static function RenameStation(stationId, stationName);
}

function StationName::IndustryShortName(industryId)
{
  local sliceEnd = 3;
  local industryName = AIIndustry.GetName(industryId);
  if (sliceEnd > industryName.len())
  {
    sliceEnd = industryName.len();
  }
  return industryName.slice(0, sliceEnd).toupper();
}

function StationName::RenameStation(stationId, stationName)
{
  local i = 1;
  local newStationName = stationName;
  AILog.Info("Trying to rename station to " + newStationName);
  local success = false;
  do
  {
    success = AIBaseStation.SetName(stationId, newStationName);
    if (!success && AIError.GetLastError() != AIError.ERR_NAME_IS_NOT_UNIQUE)
    {
      AILog.Warning("Could not rename station: " + AIError.GetLastErrorString());
      break;
    }
    i++;
    newStationName = stationName + " " + i;
  } while (!success);
}