require("Action.nut")
require("../RoadHelpers.nut")

class BuildTrucksAction extends Action
{
  constructor(context, engineId, cargoId, producerId, consumerId, producerTileKey, consumerTileKey, depotTileKey)
  {
    ::Action.constructor();
    this.engineId = engineId;
    this.cargoId = cargoId;
    this.producerTileKey = producerTileKey;
    this.consumerTileKey = consumerTileKey;
    this.depotTileKey = depotTileKey;

    local production = AIIndustry.GetLastMonthProduction(producerId, cargoId);
    local capacity = AIEngine.GetCapacity(engineId);
    local distance = AIIndustry.GetDistanceManhattanToTile(producerId, AIIndustry.GetLocation(consumerId));
    this.nTrucks = 1.0 * production / capacity * distance / 50 + 1;
  }

  function Name(context);
  function _Do(context);
  function _Undo(context);
  function _RenameGroup(groupId, context);

  engineId = -1;
  cargoId = -1;
  producerTileKey = "";
  consumerTileKey = "";
  depotTileKey = "";
  nTrucks = 0;
}

function BuildTrucksAction::Name(context)
{
  return "Building " + this.nTrucks + " trucks for " + context.shortConnectionName;
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
  local depotTile = context.rawget(this.depotTileKey);
  for (local i = 0; i < this.nTrucks; i++)
  {
    local vehicleId = RoadHelpers.BuildTruck(depotTile, engineId);
    try
    {
      RoadHelpers.RefitTruck(vehicleId, cargoId);
    }
    catch (ex)
    {
      AIVehicle.SellVehicle(vehicleId);
      throw ex;
    }
    AIGroup.MoveVehicle(groupId, vehicleId);
    local producerTile = context.rawget(this.producerTileKey);
    AIOrder.AppendOrder(vehicleId, producerTile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
    local consumerTile = context.rawget(this.consumerTileKey);
    AIOrder.AppendOrder(vehicleId, consumerTile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_UNLOAD | AIOrder.OF_NO_LOAD);
    AIOrder.AppendOrder(vehicleId, depotTile, AIOrder.OF_SERVICE_IF_NEEDED | AIOrder.OF_NON_STOP_INTERMEDIATE);
    AIVehicle.StartStopVehicle(vehicleId);
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
