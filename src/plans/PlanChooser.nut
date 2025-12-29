require("RoadConnectionPlan.nut");
require("../game/PersistentStorage.nut");

import("util.superlib", "SuperLib", 40);

class PlanChooser
{
  function NextPlan();

  function NextRoadConnectionPlan();

  function _ReasonableCargosToPickup(industryId);
  function _CargoIndustryBestConsumerAndEval(cargoId, industryId);

  static function IsCargoSuppliedByIndustry(station_id, cargo_id, industry_id);

  static minTrucksLeftToBuildRoute = 50;
}

function PlanChooser::NextPlan()
{
  if (SuperLib.Vehicle.GetVehiclesLeft(AIVehicle.VT_ROAD) >= minTrucksLeftToBuildRoute)
  {
    return NextRoadConnectionPlan();
  }
  return null;
}

function PlanChooser::IsCargoSuppliedByIndustry(station_id, cargo_id, industry_id)
{
  // We use this function instead of SuperLib.Station.IsCargoSuppliedByIndustry
  // because the latter has a bug whenever an industry produces at a tile that is not industry tile (like oil rigs).
	local max_coverage_radius = SuperLib.Station.GetMaxCoverageRadius(station_id);

	local industry_coverage_tiles = AITileList_IndustryProducing(industry_id, max_coverage_radius);
	industry_coverage_tiles.Valuate(SuperLib.Station.IsStation, station_id);
	industry_coverage_tiles.KeepValue(1);

	return !industry_coverage_tiles.IsEmpty() && SuperLib.Industry.IsCargoProduced(industry_id, cargo_id);
}

function PlanChooser::NextRoadConnectionPlan()
{
  local allIndustries = AIIndustryList();
  local bestEval = -1;
  local bestProducer = -1;
  local bestCargo = -1;
  local bestConsumer = -1;
  local unusableIndustries = PersistentStorage.LoadUnusableIndustries();
  for (local industryId = allIndustries.Begin(); !allIndustries.IsEnd(); industryId = allIndustries.Next())
  {
    if (industryId in unusableIndustries)
    {
      continue;
    }
    local cargos = _ReasonableCargosToPickup(industryId);
    for (local cargoId = cargos.Begin(); !cargos.IsEnd(); cargoId = cargos.Next())
    {
      local consumerAndEval = _CargoIndustryBestConsumerAndEval(cargoId, industryId);
      if (consumerAndEval != null && consumerAndEval.eval > bestEval)
      {
        bestEval = consumerAndEval.eval;
        bestProducer = industryId;
        bestCargo = cargoId;
        bestConsumer = consumerAndEval.consumerId;
      }
    }
  }

  if (bestEval < 0)
  {
    AILog.Warning("Could not find any possible road connections.");
    return null;
  }
  AILog.Info("Best connection is from " + AIIndustry.GetName(bestProducer) +
             " to " + AIIndustry.GetName(bestConsumer) +
             " with cargo " + AICargo.GetCargoLabel(bestCargo));
  return RoadConnectionPlan(bestProducer, bestConsumer, bestCargo);
}

function PlanChooser::_ReasonableCargosToPickup(industryId)
{
  // Find the cargo which this industry produces and is "most profitable"
  local cargos = AICargoList_IndustryProducing(industryId);
  // Exclude cargos which no trucks can carry
  cargos.Valuate(SuperLib.Engine.DoesEngineExistForCargo, AIVehicle.VT_ROAD);
  cargos.KeepValue(1);
  // Exclude cargos that were not produced by this industry last month
  local lastMonthProductionFun = function(cargo, industry)
  {
    return AIIndustry.GetLastMonthProduction(industry, cargo);
  };
  cargos.Valuate(lastMonthProductionFun, industryId);
  cargos.KeepAboveValue(0);
  // Exclude cargos that are already being transported by other competitors, or by us
  local lastMonthTransportedPercentFun = function(cargo, industry)
  {
    return AIIndustry.GetLastMonthTransportedPercentage(industry, cargo);
  }
  cargos.Valuate(lastMonthTransportedPercentFun, industryId);
  cargos.KeepValue(0);
  // The previous filter doesn't work in the first month of route. So filter also our stations that accept this cargo.
  local isPickedByOurStation = function(cargoId, industryId)
  {
    local stations = AIStationList(AIStation.STATION_ANY);
    stations.Valuate(AIStation.HasCargoRating, cargoId);
    stations.KeepValue(1);
    stations.Valuate(PlanChooser.IsCargoSuppliedByIndustry, cargoId, industryId);
    stations.KeepValue(1);
    return !stations.IsEmpty();
  }
  cargos.Valuate(isPickedByOurStation, industryId);
  cargos.KeepValue(0);
  return cargos;
}

// For the pair (cargo, producer industry), calculate pair (how good is this combination, best consumer for this combination).
function PlanChooser::_CargoIndustryBestConsumerAndEval(cargoId, producerId)
{
  local consumers = AIIndustryList_CargoAccepting(cargoId);
  consumers.RemoveItem(producerId); // not allowing connections from an industry to itself
  local unusableIndustries = PersistentStorage.LoadUnusableIndustries();
  foreach (unusableIndustry,_ in unusableIndustries)
  {
    consumers.RemoveItem(unusableIndustry);
  }
  if (consumers.IsEmpty())
  {
    return null; // no consumers accepting this cargo
  }

  local bestConsumerId = -1;
  local bestEval = -100000;
  const AVG_DAYS = 30;
  const BEST_DISTANCE_TO_DROP = 100;
  local consumerEval = function(consumerId, cargoId, producerId)
  {
    local production = AIIndustry.GetLastMonthProduction(producerId, cargoId);
    local distance = AIIndustry.GetDistanceManhattanToTile(producerId, AIIndustry.GetLocation(consumerId));
    local distanceFactor = 1 - abs(distance - BEST_DISTANCE_TO_DROP) / BEST_DISTANCE_TO_DROP;
    local cargoIncome = AICargo.GetCargoIncome(cargoId, distance, AVG_DAYS);
    return production * distanceFactor * cargoIncome;
  };
  consumers.Valuate(consumerEval, cargoId, producerId);
  consumers.Sort(AIList.SORT_BY_VALUE, false); // descending
  local bestConsumer = consumers.Begin();
  local bestEval = consumers.GetValue(bestConsumer);
  if (bestEval <= 0)
  {
    return null; // no reasonable consumers
  }
  return { consumerId = bestConsumer, eval = bestEval };
}
