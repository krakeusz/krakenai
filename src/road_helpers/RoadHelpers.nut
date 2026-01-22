import("util.superlib", "SuperLib", 40);

class RoadHelpers
{
  static function BuildRoadVehicle(depotTile, engineId); // returns vehicleId or throws
  static function CloneRoadVehicle(depotTile, templateVehicle);
  static function RefitRoadVehicle(vehicleId, cargoId);
  static function PrintRoadBuildError(fromTile, toTile, entityName);
  static function BuildRoad(fromTile, toTile); // returns or throws
  static function BuildDepotNextToRoad(roadTile);
  static function BuildBridge(vehicleType, bridgeId, fromTile, toTile);
  static function BuildTunnel(vehicleType, fromTile, toTile);
  static function BuildRoroStation(stationTile, entranceTile, roadVehicleType, stationId);
  static function WaitForFundsWithMargin(fundsRequired);
  static function StationCapacityInTrucks(stationTile, engineId, cargoId);
  static function RoadStationTypeForCargo(cargoId);
  static function _Delay(reason, ticks);

  // This function could be slow, because if we don't have any vehicles with given engineId, we will build and sell one.
  //! @param engineId ID of engine in question.
  //! @param testDepotId ID of a depo, that could be used to buy and sell a temporary vehicle.
  //! @return engine length in 1/16th of a tile
  static function FindEngineLength(engineId, testDepotId);

  static function FindAnyVehicle(engineId);

  // Get the list of vehicles that have the station on their order list and are close to it.
  static function IncomingTrucks(stationId);

  static function IsTruckGroupUnprofitable(groupId);
}

function RoadHelpers::BuildRoadVehicle(depotTile, engineId)
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

function RoadHelpers::CloneRoadVehicle(depotTile, templateVehicle)
{
  local vehicleId = -1;
  local cloneSuccessful = false;
  while (!cloneSuccessful)
  {
    local shareOrders = true;
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

function RoadHelpers::RefitRoadVehicle(vehicleId, cargoId)
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
        return true;
      case AIError.ERR_VEHICLE_IN_THE_WAY:
        RoadHelpers._Delay("Cannot build bridge: vehicle in the way", 10);
        break;
      default:
        RoadHelpers.PrintRoadBuildError(fromTile, toTile, "bridge");
        throw "Error while building bridge"
    }
  }
  return true;
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
  return AIStation.GetStationID(stationTile);
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

// vehicleLength is in 1/16th of a tile
function RoadHelpers::StationCapacityInTrucks(stationTile, vehicleLength, cargoId)
{
  local stationType = RoadHelpers.RoadStationTypeForCargo(cargoId);
  local stationId = AIStation.GetStationID(stationTile);
  local stationTiles = AITileList_StationType(stationId, stationType);
  local stationTileCount = stationTiles.Count();
  // Assuming that station tiles are connected "parallelly", not in "series".
  local vehiclesPerStationTile = SuperLib.Helper.Max(1, 16 / vehicleLength.tointeger());
  assert(typeof(vehiclesPerStationTile) == "integer");
  const TRAFFIC_LANES_PER_ROAD = 2;
  return stationTileCount * vehiclesPerStationTile * TRAFFIC_LANES_PER_ROAD;
}

function RoadHelpers::RoadStationTypeForCargo(cargoId)
{
  local roadVehicleType = AIRoad.GetRoadVehicleTypeForCargo(cargoId);
  switch (roadVehicleType)
  {
    case AIRoad.ROADVEHTYPE_BUS:
      return AIStation.STATION_BUS_STOP;
    case AIRoad.ROADVEHTYPE_TRUCK:
      return AIStation.STATION_TRUCK_STOP;
    default:
      throw "Invalid RoadVehicleType: " + roadVehicleType;  
  }
}

function RoadHelpers::FindEngineLength(engineId, testDepotTile)
{
  // It's a shame that the NoAI API requires a vehicle to be built, if we want to get engine length.
  // Let's check first if we have, by any chance, an instance of the engine - a vehicle.
  local anyVehicle = RoadHelpers.FindAnyVehicle(engineId);
  if (anyVehicle != null)
  {
    return AIVehicle.GetLength(anyVehicle);
  }
  
  // Build a vehicle, then sell it.
  local tempVehicleId = RoadHelpers.BuildRoadVehicle(testDepotTile, engineId);
  local engineLength = AIVehicle.GetLength(tempVehicleId);
  AIVehicle.SellVehicle(tempVehicleId);
  return engineLength;
}

function RoadHelpers::FindAnyVehicle(engineId)
{
  local myVehicles = AIVehicleList();
  myVehicles.Valuate(AIVehicle.GetEngineType);
  myVehicles.KeepValue(engineId);
  if (myVehicles.IsEmpty())
  {
    return null;
  }
  return myVehicles.Begin();
}

function RoadHelpers::IncomingTrucksCount(stationId)
{
  return RoadHelpers.IncomingTrucks(stationId).Count();
}

function RoadHelpers::IncomingTrucks(stationId)
{
  local vehicles = AIVehicleList_Station(stationId);
  local stationTile = AIStation.GetLocation(stationId);
  local distanceEval = function(vehicleId, stationTile)
  {
    return AITile.GetDistanceManhattanToTile(stationTile, AIVehicle.GetLocation(vehicleId));
  };
  vehicles.Valuate(distanceEval, stationTile);
  const STATION_DISTANCE_THRESHOLD = 8;
  vehicles.RemoveAboveValue(STATION_DISTANCE_THRESHOLD);

  vehicles.Valuate(AIVehicle.GetState);
  vehicles.RemoveValue(AIVehicle.VS_STOPPED);
  vehicles.RemoveValue(AIVehicle.VS_IN_DEPOT);
  vehicles.RemoveValue(AIVehicle.VS_CRASHED);
  vehicles.RemoveValue(AIVehicle.VS_BROKEN);
  return vehicles;
}

function RoadHelpers::IsTruckGroupUnprofitable(groupId)
{
  local truckCount = AIGroup.GetNumVehicles(groupId, AIVehicle.VT_ROAD);
  if (truckCount == 0)
  {
    return false;
  }

  local trucks = AIVehicleList_Group(groupId);
  trucks.Valuate(AIVehicle.GetAge);
  trucks.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
  if (trucks.GetValue(trucks.Begin()) < 400) // days
  {
    return false;
  }

  trucks.Valuate(TruckOrders.IsStoppingAtDepot);
  local sum = 0;
  for (local item = trucks.Begin(); !trucks.IsEnd(); item = trucks.Next())
  {
    sum = sum + trucks.GetValue(item);
  }
  if (sum == truckCount)
  {
    return false; // All trucks are stopping at depot, meaning that the route is being wound down.
  }

  local profit = AIGroup.GetProfitThisYear(groupId) + AIGroup.GetProfitLastYear(groupId);
  if (profit > 0)
  {
    return false;
  }
  AILog.Info("Group " + AIGroup.GetName(groupId) + " is unprofitable with profit " + profit + " over this and the previous year.");
  return true;
}

function RoadHelpers::GetUnprofitableTruckGroups()
{
  return AIGroupList(RoadHelpers.IsTruckGroupUnprofitable);
}
