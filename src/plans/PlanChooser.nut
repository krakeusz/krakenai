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
  static function _IsIndustryAlreadyServicedByUs(industryId);

  static minTrucksLeftToBuildRoute = 50;
}

class RoadConnectionPlanData
{
  producer = -1;
  consumer = -1;
  cargo = -1;
  eval = -1;

  constructor(producer, consumer, cargo, eval)
  {
    this.producer = producer;
    this.consumer = consumer;
    this.cargo = cargo;
    this.eval = eval;
  }
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

function PlanChooser::GetWeightedRandomPlan(plans /* array[RoadConnectionPlanData] */, sortedEvals /* AIList[index(int), eval(int)] */)
{
  if (plans.len() == 0)
  {
    AILog.Warning("Could not find any possible road connections. Maybe all industries are served, or no trucks can carry the cargos produced?");
    return null;
  }
  if (plans.len() != sortedEvals.Count())
  {
    AILog.Error("Error in GetWeightedRandomPlan logic: plans.len() != sortedEvals.len()");
    return null;
  }
  AILog.Info("Found " + plans.len() + " possible road connections. Best ones:");
  local plansToChoose = min(5, plans.len());
  for (local i = 0, j = sortedEvals.Begin(); i < plansToChoose && ! sortedEvals.IsEnd(); i++, j = sortedEvals.Next())
  {
    local plan = plans[j];
    AILog.Info("  From " + AIIndustry.GetName(plan.producer) +
               " to " + AIIndustry.GetName(plan.consumer) +
               " with cargo " + AICargo.GetCargoLabel(plan.cargo) +
               " (eval: " + plan.eval + ")");
  }
  // every plan in the top 5 has weight 5 - its index
  local totalWeights = plansToChoose * (plansToChoose + 1) / 2;
  local random = AIBase.RandRange(totalWeights);
  for (local i = 0, j = sortedEvals.Begin(); i < plansToChoose && ! sortedEvals.IsEnd(); i++, j = sortedEvals.Next())
  {
    local weight = plansToChoose - i;
    if (random < weight)
    {
      AILog.Info("Selected plan from " + AIIndustry.GetName(plans[j].producer) +
                 " to " + AIIndustry.GetName(plans[j].consumer) +
                 " with cargo " + AICargo.GetCargoLabel(plans[j].cargo));
      return plans[j];
    }
    random -= weight;
  }

  AILog.Error("Error in GetWeightedRandomPlan logic: random selection failed.");
  return null;
}

function PlanChooser::NextRoadConnectionPlan()
{
  local allIndustries = AIIndustryList();
  local allPlans = [];
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
      if (consumerAndEval != null)
      {
        allPlans.push(RoadConnectionPlanData(industryId, consumerAndEval.consumerId, cargoId, consumerAndEval.eval));
      }
    }
  }
  local allEvals = AIList();
  for (local i = 0; i < allPlans.len(); i++)
  {
    allEvals.AddItem(i, allPlans[i].eval);
  }
  allEvals.Sort(AIList.SORT_BY_VALUE, false); // descending
  local bestPlan = GetWeightedRandomPlan(allPlans, allEvals);
  return bestPlan != null ? RoadConnectionPlan(bestPlan.producer, bestPlan.consumer, bestPlan.cargo) : null;
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
    local synergyFactor = 1.0;
    if (PlanChooser._IsIndustryAlreadyServicedByUs(consumerId))
    {
      synergyFactor *= 1.2;
    }
    if (PlanChooser._IsIndustryAlreadyServicedByUs(producerId))
    {
      synergyFactor *= 1.2;
    }
    return (production * distanceFactor * cargoIncome * synergyFactor).tointeger();
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


function PlanChooser::_IsIndustryAlreadyServicedByUs(industryId)
{
  return PersistentStorage.LoadIndustryStations().getRelations(industryId).len() > 0;
}