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

  engineId = -1;
  cargoId = -1;
  producerTileKey = "";
  consumerTileKey = "";
  depotTileKey = "";
  nTrucks = 0;
}

function BuildTrucksAction::Name(context)
{
  return "Building " + this.nTrucks + " trucks for " + context.connectionName;
}

function BuildTrucksAction::_Do(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  local depotTile = context.rawget(this.depotTileKey);
  for (local i = 0; i < this.nTrucks; i++)
  {
    local vehicleId = RoadHelpers.BuildTruck(depotTile, engineId);
    if (!AIVehicle.RefitVehicle(vehicleId, this.cargoId)) {
      AIVehicle.SellVehicle(vehicleId);
      throw "Cannot refit vehicle " + AIEngine.GetName(engineId) + " to cargo " + AICargo.GetCargoLabel(cargoId);
    }
    local producerTile = context.rawget(this.producerTileKey);
    AIOrder.AppendOrder(vehicleId, producerTile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
    local consumerTile = context.rawget(this.consumerTileKey);
    AIOrder.AppendOrder(vehicleId, consumerTile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_UNLOAD);
    AIOrder.AppendOrder(vehicleId, depotTile, AIOrder.OF_SERVICE_IF_NEEDED | AIOrder.OF_NON_STOP_INTERMEDIATE);
    AIVehicle.StartStopVehicle(vehicleId);
  }
  return true;
}

function BuildTrucksAction::_Undo(context)
{
}
