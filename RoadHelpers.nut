class RoadHelpers
{
  static function BuildTruck(depotTile, vehicleId); // returns vehicleId or throws
  static function PrintRoadBuildError(tileA, tileB, entityName);
  static function BuildRoad(fromTile, toTile); // returns or throws
  static function _Delay(reason, ticks);
}

function RoadHelpers::BuildTruck(depotTile, engineId)
{
  local vehicleId = -1;
  local buildSuccessful = false;
  while (!buildSuccessful)
  {
    vehicleId = AIVehicle.BuildVehicle(depotTile, engineId);
    if (!AIVehicle.IsValidVehicle(vehicleId))
    {
      switch (AIError.GetLastError())
      {
        case AIError.ERR_NOT_ENOUGH_CASH:
          RoadHelpers._Delay("Not enough cash to build vehicle", 50);
          break;
        default:
          throw "Cannot build vehicle " + AIEngine.GetName(engineId) + ": " + AIError.GetLastErrorString();
      }
    }
    else
    {
      buildSuccessful = true;
    }
  }
  return vehicleId;
}

function RoadHelpers::PrintRoadBuildError(tileA, tileB, entityName)
{
  AILog.Error("Cannot build " + entityName + " between " + SuperLib.Tile.GetTileString(tileA) + " and " +
      SuperLib.Tile.GetTileString(tileB) + ": " + AIError.GetLastErrorString());
}

function RoadHelpers::BuildRoad(fromTile, toTile)
{
  while (!AIRoad.BuildRoad(fromTile, toTile)) {
    switch (AIError.GetLastError())
    {
      case AIError.ERR_NOT_ENOUGH_CASH:
        RoadHelpers._Delay("Not enough cash to build road", 50);
        break;
      case AIError.ERR_ALREADY_BUILT:
        return;
      case AIError.ERR_VEHICLE_IN_THE_WAY:
        RoadHelpers._Delay("Cannot build road: vehicle in the way", 10);
        break;
      default:
        RoadHelpers.PrintRoadBuildError(fromTile, toTile, "road segment");
        throw "Error while building road segment"
    }
  }
}

function RoadHelpers::_Delay(reason, ticks)
{
  AILog.Warning(reason + ", will try again in " + ticks + " ticks...");
  AIController.Sleep(ticks);
}
