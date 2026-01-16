require("Action.nut")
require("../road_helpers/RoadHelpers.nut")
require("../road_helpers/TruckOrders.nut")

class BuildTrucksAction extends Action
{
  constructor(context, engineId, cargoId, producerId, consumerId, producerTileKey, consumerTileKey, depot1TileKey, depot2TileKey, isRoundTrip)
  {
    ::Action.constructor();
    this.engineId = engineId;
    this.cargoId = cargoId;
    this.producerTileKey = producerTileKey;
    this.consumerTileKey = consumerTileKey;
    this.depot1TileKey = depot1TileKey;
    this.depot2TileKey = depot2TileKey;
    this.isRoundTrip = isRoundTrip;

    local production = AIIndustry.GetLastMonthProduction(producerId, cargoId);
    local capacity = AIEngine.GetCapacity(engineId);
    local distance = AIIndustry.GetDistanceManhattanToTile(producerId, AIIndustry.GetLocation(consumerId));
    this.nTrucks = 1.0 * production / capacity * distance / 50 + 1;
  }

  function Name(context);
  function _Do(context);
  function _Undo(context);
  function _RenameGroup(groupId, context);
  function _AdjustTruckCountToStationSize(context);

  engineId = -1;
  cargoId = -1;
  producerTileKey = "";
  consumerTileKey = "";
  depot1TileKey = "";
  depot2TileKey = "";
  nTrucks = 0;
  isRoundTrip = false;
}

function BuildTrucksAction::Name(context)
{
  return "Building at most " + this.nTrucks + " trucks for " + context.connectionName + " (round trip: " + (this.isRoundTrip ? "yes" : "no") + ")";
}

function BuildTrucksAction::_Do(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local groupId = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
  if (!AIGroup.IsValidGroup(groupId))
  {
    throw "Cannot create group: " + AIError.GetLastErrorString();
  }
  _RenameGroup(groupId, context);
  local depot1Tile = context.rawget(this.depot1TileKey);
  local depot2Tile = context.rawget(this.depot2TileKey);
  _AdjustTruckCountToStationSize(context);
  local firstVehicleId = -1;
  for (local i = 0; i < this.nTrucks; i++)
  {
    local vehicleId = RoadHelpers.BuildRoadVehicle(depot1Tile, engineId);
    if (i == 0)
    {
      firstVehicleId = vehicleId;
    }
    try
    {
      RoadHelpers.RefitRoadVehicle(vehicleId, cargoId);
    }
    catch (ex)
    {
      AIVehicle.SellVehicle(vehicleId);
      throw ex;
    }

    AIGroup.MoveVehicle(groupId, vehicleId);
    if (i == 0)
    {
      local producerTile = context.rawget(this.producerTileKey);
      local consumerTile = context.rawget(this.consumerTileKey);
      TruckOrders.SetDefaultTruckOrders(vehicleId, producerTile, consumerTile, depot1Tile, depot2Tile, this.isRoundTrip);
    }
    else
    {
      AIOrder.ShareOrders(vehicleId, firstVehicleId);
    }
  }
  return true;
}

function BuildTrucksAction::_Undo(context)
{
}

function BuildTrucksAction::_RenameGroup(groupId, context)
{
  local i = 1;
  local newGroupName = context.shortConnectionName;
  AILog.Info("Trying to rename group to " + newGroupName);
  local success = false;
  do
  {
    success = AIGroup.SetName(groupId, newGroupName);
    if (!success && AIError.GetLastError() != AIError.ERR_NAME_IS_NOT_UNIQUE)
    {
      AILog.Warning("Could not rename group: " + AIError.GetLastErrorString());
      break;
    }
    i++;
    newGroupName = context.shortConnectionName + " " + i;
  } while (!success);

}

function BuildTrucksAction::_AdjustTruckCountToStationSize(context)
{
  local depotTile = context.rawget(this.depot1TileKey);
  local engineLength = RoadHelpers.FindEngineLength(engineId, depotTile);
  local stationTile = context.rawget(this.producerTileKey);
  local stationCapacityInTrucks = RoadHelpers.StationCapacityInTrucks(stationTile, engineLength, cargoId);
  if (stationCapacityInTrucks < nTrucks)
  {
    nTrucks = stationCapacityInTrucks;
  }
}
