require("Plan.nut");

require("../actions/BuildTrucksAction.nut");
require("../actions/FindAndBuildRoadAction.nut");
require("../actions/ProvideDepotAction.nut");
require("../actions/ProvideStationAction.nut");
require("../actions/WaitForFirstTruckAtPickupAction.nut");

class RoadConnectionPlan extends Plan
{
  constructor(producerId, consumerId, cargoId)
  {
    ::Plan.constructor();

    context.producerId <- producerId;
    context.consumerId <- consumerId;
    context.cargoId <- cargoId;
    this.name = AIIndustry.GetName(producerId) + " - " + AIIndustry.GetName(consumerId) + " (" + AICargo.GetCargoLabel(cargoId) + ")";
    context.connectionName <- this.name;
    context.shortConnectionName <- AICargo.GetCargoLabel(cargoId) + " " + _IndustryShortName(producerId) + "-" + _IndustryShortName(consumerId);

    local producerTileKey = "producerStationTile";
    local producerStationName = _IndustryShortName(producerId) + " " + AICargo.GetCargoLabel(cargoId) + " PICKUP";
    _AddAction(ProvideStationAction(context, producerId, cargoId, producerTileKey, 1, producerStationName));
    local consumerTileKey = "consumerStationTile";
    local consumerStationName = _IndustryShortName(consumerId) + " " + AICargo.GetCargoLabel(cargoId) + " DROP";
    _AddAction(ProvideStationAction(context, consumerId, cargoId, consumerTileKey, 0, consumerStationName));
    _AddAction(FindAndBuildRoadAction(context, producerTileKey + "entrance", consumerTileKey + "entrance"));
    local depot1Name = producerStationName + " depot";
    _AddAction(ProvideDepotAction(context, producerTileKey + "entrance", depot1Name));
    local depot2Name = consumerStationName + " depot";
    _AddAction(ProvideDepotAction(context, consumerTileKey + "entrance", depot2Name));
    local bestEngineId = _ChooseBestEngineId(cargoId);
    _AddAction(BuildTrucksAction(context, bestEngineId, cargoId, producerId, consumerId, producerTileKey, consumerTileKey, depot1Name + "_tile", depot2Name + "_tile"));
    _AddAction(WaitForFirstTruckAtPickupAction(context, producerStationName, producerTileKey, cargoId));
  }

  function Name();

  static function _ChooseBestEngineId(cargoId);
  static function _EngineEval(engineId);
  static function _IndustryShortName(industryId);

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

function RoadConnectionPlan::_IndustryShortName(industryId)
{
  local sliceEnd = 3;
  local industryName = AIIndustry.GetName(industryId);
  if (sliceEnd > industryName.len())
  {
    sliceEnd = industryName.len();
  }
  return industryName.slice(0, sliceEnd).toupper();
}

function RoadConnectionPlan::Name()
{
  return this.name;
}
