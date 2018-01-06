import("util.superlib", "SuperLib", 40);

class RoadHelpers
{
  static function BuildTruck(depotTile, vehicleId); // returns vehicleId or throws
  static function CloneTruck(depotTile, templateVehicle);
  static function RefitTruck(vehicleId, cargoId);
  static function PrintRoadBuildError(fromTile, toTile, entityName);
  static function BuildRoad(fromTile, toTile); // returns or throws
  static function BuildDepotNextToRoad(roadTile);
  static function BuildBridge(vehicleType, bridgeId, fromTile, toTile);
  static function BuildTunnel(vehicleType, fromTile, toTile);
  static function BuildRoroStation(stationTile, entranceTile, roadVehicleType, stationId);
  static function WaitForFundsWithMargin(fundsRequired);
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

function RoadHelpers::CloneTruck(depotTile, templateVehicle)
{
  local vehicleId = -1;
  local cloneSuccessful = false;
  while (!cloneSuccessful)
  {
    local shareOrders = false;
    vehicleId = AIVehicle.CloneVehicle(depotTile, templateVehicle, shareOrders);
    if (!AIVehicle.IsValidVehicle(vehicleId))
    {
      switch (AIError.GetLastError())
      {
        case AIError.ERR_NOT_ENOUGH_CASH:
          RoadHelpers._Delay("Not enough cash to clone vehicle", 50);
          break;
        default:
          throw "Cannot clone vehicle " + AIVehicle.GetName(templateVehicle) + ": " + AIError.GetLastErrorString();
      }
    }
    else
    {
      cloneSuccessful = true;
    }
  }
  return vehicleId;
}

function RoadHelpers::RefitTruck(vehicleId, cargoId)
{
  local refitSuccessful = false;
  while (!refitSuccessful)
  {
    refitSuccessful = AIVehicle.RefitVehicle(vehicleId, cargoId);
    if (!refitSuccessful)
    {
      switch (AIError.GetLastError())
      {
        case AIError.ERR_NOT_ENOUGH_CASH:
          RoadHelpers._Delay("Not enough cash to refit vehicle", 50);
          break;
        default:
          throw "Cannot refit vehicle " + AIVehicle.GetName(vehicleId) + " to " + AICargo.GetCargoLabel(cargoId) + ": " + AIError.GetLastErrorString();
      }
    }
  }
  return vehicleId;
}

function RoadHelpers::PrintRoadBuildError(fromTile, toTile, entityName)
{
  AILog.Error("Cannot build " + entityName + " between " + SuperLib.Tile.GetTileString(fromTile) + " and " +
      SuperLib.Tile.GetTileString(toTile) + ": " + AIError.GetLastErrorString());
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

function RoadHelpers::BuildDepotNextToRoad(roadTile)
{
  // TODO this will fail if the entrance tile is not a road, but a bridge
  local depotTile = null;
  local retriesLeft = 6;
  while (retriesLeft > 0 && depotTile == null)
  {
    depotTile = SuperLib.Road.BuildDepotNextToRoad(roadTile, 1, 20);
    retriesLeft--;
    if (depotTile == null)
    {
      RoadHelpers._Delay("Could not build a depot, probably because we're low on cash", 100);
    }
  }
  if (null == depotTile) throw "Could not build a depot!";
  return depotTile;
}

function RoadHelpers::BuildBridge(vehicleType, bridgeId, fromTile, toTile)
{
  while (!AIBridge.BuildBridge(vehicleType, bridgeId, fromTile, toTile)) {
    switch (AIError.GetLastError())
    {
      case AIError.ERR_NOT_ENOUGH_CASH:
        RoadHelpers._Delay("Not enough cash to build bridge", 50);
        break;
      case AIError.ERR_ALREADY_BUILT:
        return;
      case AIError.ERR_VEHICLE_IN_THE_WAY:
        RoadHelpers._Delay("Cannot build bridge: vehicle in the way", 10);
        break;
      default:
        RoadHelpers.PrintRoadBuildError(fromTile, toTile, "bridge");
        throw "Error while building bridge"
    }
  }
}

function RoadHelpers::BuildTunnel(vehicleType, fromTile, toTile)
{
  while (!AITunnel.BuildTunnel(vehicleType, fromTile)) {
    switch (AIError.GetLastError())
    {
      case AIError.ERR_NOT_ENOUGH_CASH:
        RoadHelpers._Delay("Not enough cash to build tunnel", 50);
        break;
      case AIError.ERR_ALREADY_BUILT:
        return;
      case AIError.ERR_VEHICLE_IN_THE_WAY:
        RoadHelpers._Delay("Cannot build tunnel: vehicle in the way", 10);
        break;
      default:
        RoadHelpers.PrintRoadBuildError(fromTile, toTile, "tunnel");
        throw "Error while building tunnel"
    }
  }
}

function RoadHelpers::BuildRoroStation(stationTile, entranceTile, roadVehicleType, stationId)
{
  while (!AIRoad.BuildDriveThroughRoadStation(stationTile, entranceTile, roadVehicleType, stationId))
  {
    switch (AIError.GetLastError())
    {
      case AIError.ERR_NOT_ENOUGH_CASH:
        RoadHelpers._Delay("Not enough cash to build station", 50);
        break;
      default:
        throw "Error while building roro station " + AIError.GetLastErrorString()
    }
  }
}

function RoadHelpers::WaitForFundsWithMargin(fundsRequired)
{
  const MARGIN = 10;
  while (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < fundsRequired + MARGIN)
  {
    RoadHelpers._Delay("Not enough cash, waiting until we have " + (fundsRequired+MARGIN), 50);
  }
}

function RoadHelpers::_Delay(reason, ticks)
{
  AILog.Warning(reason + ", will try again in " + ticks + " ticks...");
  AIController.Sleep(ticks);
}
