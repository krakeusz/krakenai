require("Plan.nut");

require("../actions/BuildTrucksAction.nut");
require("../actions/FindAndBuildRoadAction.nut");
require("../actions/ProvideDepotAction.nut");
require("../actions/ProvideStationAction.nut");
require("../actions/WaitForFirstTruckAtPickupAction.nut");
require("../names/StationName.nut");

class RoadConnectionPlan extends Plan
{
  constructor(producerId, consumerId, cargoId, isRoundTrip)
  {
    ::Plan.constructor();

    context.producerId <- producerId;
    context.consumerId <- consumerId;
    context.cargoId <- cargoId;
    context.isRoundTrip <- isRoundTrip;
    this.name = AIIndustry.GetName(producerId) + " - " + AIIndustry.GetName(consumerId) + " (" + AICargo.GetCargoLabel(cargoId) + ")";
    context.connectionName <- this.name;
    context.shortConnectionName <- AICargo.GetCargoLabel(cargoId) + " " + StationName.IndustryShortName(producerId) + "-" + StationName.IndustryShortName(consumerId);

    local producerTileKey = "producerStationTile";
    local producerStationName = AIIndustry.GetName(producerId) + " " + AICargo.GetName(cargoId) + " PICKUP";
    _AddAction(ProvideStationAction(context, producerId, cargoId, producerTileKey, 1, producerStationName));
    local consumerTileKey = "consumerStationTile";
    local consumerStationName = AIIndustry.GetName(consumerId) + " " + AICargo.GetName(cargoId) + " DROP";
    _AddAction(ProvideStationAction(context, consumerId, cargoId, consumerTileKey, 0, consumerStationName));
    _AddAction(FindAndBuildRoadAction(context, producerTileKey + "entrance", consumerTileKey + "entrance"));
    local depot1Name = producerStationName + " depot";
    _AddAction(ProvideDepotAction(context, producerTileKey + "entrance", depot1Name));
    local depot2Name = consumerStationName + " depot";
    _AddAction(ProvideDepotAction(context, consumerTileKey + "entrance", depot2Name));
    local bestEngineId = _ChooseBestEngineId(cargoId);
    _AddAction(BuildTrucksAction(context, bestEngineId, cargoId, producerId, consumerId, producerTileKey, consumerTileKey, depot1Name + "_tile", depot2Name + "_tile", isRoundTrip));
    _AddAction(WaitForFirstTruckAtPickupAction(context, producerStationName, producerTileKey, cargoId));
  }

  function Name();

  static function _ChooseBestEngineId(cargoId);
  static function _EngineEval(engineId);

  name = "";
}

function RoadConnectionPlan::_ChooseBestEngineId(cargoId)
{
  local engines = AIEngineList(AIVehicle.VT_ROAD);
  engines.Valuate(AIEngine.GetRoadType);
  engines.KeepValue(AIRoad.ROADTYPE_ROAD); // no trams
  engines.Valuate(AIEngine.IsBuildable);
  engines.KeepValue(1);
  engines.Valuate(AIEngine.CanRefitCargo, cargoId);
  engines.KeepValue(1);
  if (engines.IsEmpty()) throw "No engines found for " + cargoId;

  engines.Valuate(_EngineEval);
  return engines.Begin();
}

function RoadConnectionPlan::_EngineEval(engineId)
{
  return AIEngine.GetMaxSpeed(engineId) * AIEngine.GetCapacity(engineId) * AIEngine.GetReliability(engineId);
}

function RoadConnectionPlan::Name()
{
  return this.name;
}
