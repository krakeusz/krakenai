require("plans/RoadConnectionPlan.nut");
require("BackgroundTask.nut");

class PlanChooser
{
  function NextPlan();

  function NextRoadConnectionPlan();

  static function _IndustryBestEval(industryId);
  static function _IndustryBestCargo(industryId);
  static function _IndustryBestCargoAndEval(industryId);
  static function _IndustryManhattanDistanceToCircle(industryId, circleRadius, centerTile);
  static function _FindBestProducerId();
}

function PlanChooser::NextPlan()
{
  return NextRoadConnectionPlan();
}

function PlanChooser::NextRoadConnectionPlan()
{
  local bestProducerId = _FindBestProducerId();
  if (bestProducerId == null) return null;
  local bestCargoId = _IndustryBestCargo(bestProducerId);
  local bestCargoName = AICargo.GetCargoLabel(bestCargoId);
  AILog.Info("The best cargo to carry now is " + bestCargoName);
  AILog.Info("The best industry producing " + bestCargoName + " is " + AIIndustry.GetName(bestProducerId));
  local acceptingIndustries = AIIndustryList_CargoAccepting(bestCargoId);
  if (acceptingIndustries.IsEmpty())
  {
    AILog.Warning("No industries accepting " + bestCargoName + "! Abandoning the project.");
    return null;
  }
  local BEST_DISTANCE_TO_DROP = 100;
  local producerTile = AIIndustry.GetLocation(bestProducerId);
  acceptingIndustries.Valuate(_IndustryManhattanDistanceToCircle, BEST_DISTANCE_TO_DROP, producerTile);
  acceptingIndustries.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
  local bestConsumerId = acceptingIndustries.Begin();
  AILog.Info("The best industry accepting " + bestCargoName + " is " + AIIndustry.GetName(bestConsumerId));

  return RoadConnectionPlan(bestProducerId, bestConsumerId, bestCargoId);
}

function PlanChooser::_FindBestProducerId()
{
  local industries = AIIndustryList();
  industries.Valuate(AIIndustry.GetAmountOfStationsAround); // TODO: consider multi-producing industries and so on
  industries.KeepValue(0);
  if (industries.IsEmpty())
  {
    AILog.Warning("No unserviced industries left, no action taken!");
    return null;
  }
  industries.Valuate(PlanChooser._IndustryBestEval);
  industries.KeepAboveValue(0);
  if (industries.IsEmpty())
  {
    AILog.Warning("No industries left that produced anything last month, no action taken!");
    BackgroundTask.Run();
    return null;
  }
  return industries.Begin();
}

function PlanChooser::_IndustryBestCargoAndEval(industryId)
{
  // Find the cargo which this industry produces and is "most profitable"
  local cargos = AICargoList_IndustryProducing(industryId);
  // Exclude cargos which no trucks can carry
  cargos.Valuate(SuperLib.Engine.DoesEngineExistForCargo, AIVehicle.VT_ROAD);
  cargos.KeepValue(1);
  local bestCargoId = -1;
  local bestEval = 0;
  local AVG_DISTANCE = 100;
  local AVG_DAYS = 30;
  for (local cargoId = cargos.Begin(); !cargos.IsEnd(); cargoId = cargos.Next())
  {
    local eval = AIIndustry.GetLastMonthProduction(industryId, cargoId) * AICargo.GetCargoIncome(cargoId, AVG_DISTANCE, AVG_DAYS);
    if (eval > bestEval)
    {
      bestEval = eval;
      bestCargoId = cargoId;
    }
  }
  return { cargoId = bestCargoId, eval = bestEval };
}

function PlanChooser::_IndustryBestEval(industryId)
{
  return PlanChooser._IndustryBestCargoAndEval(industryId).eval;
}

function PlanChooser::_IndustryBestCargo(industryId)
{
  return PlanChooser._IndustryBestCargoAndEval(industryId).cargoId;
}

function PlanChooser::_IndustryManhattanDistanceToCircle(industryId, circleRadius, centerTile)
{
  local distToIndustry = AIIndustry.GetDistanceManhattanToTile(industryId, centerTile);
  return abs(circleRadius - distToIndustry);
}
