import("util.superlib", "SuperLib", 40);

class Action
{
   constructor() { isDone = false; }

   // returns string: human-readable name of the plan
   function Name(context);

   // these functions return int
   function GetInitialCostEstimate();
   function GetMonthlyCostEstimate();
   function GetMonthlyIncomeEstimate();

   // return true if the action succeeded, false otherwise
   function Do(context);
   function Undo(context); // only to call after Do() finished successfully

   function _Do(context); // override in subclass
   function _Undo(context); // override in subclass

   local isDone = false;
}

function Action::Name(context)
{
   return "Unknown action";
}

function Action::GetInitialCostEstimate()
{
   return 0;
}

function Action::GetMonthlyCostEstimate()
{
   return 0;
}

function Action::GetMonthlyIncomeEstimate()
{
   return 0;
}

function Action::Do(context)
{
   if (isDone)
   {
      AILog.Error("Cannot do action " + Name() + ": action already done!");
      return false;
   }
   local result = _Do(context);
   if (result)
   {
      isDone = true;
   }
   return result;
}

function Action::Undo(context)
{
   if (!isDone)
   {
      AILog.Error("Cannon undo action " + Name() + ": action hasn't been done!");
      return false;
   }
   local result = _Undo(context);
   if (result)
   {
      isDone = false;
   }
   return result;
}

function Action::_Do(context)
{
   AILog.Error("The method " + getclass().getattributes().ClassName + "::_Do(context) is not defined!");
   return false;
}

function Action::_Undo(context)
{
   AILog.Error("The method " + getclass().getattributes().ClassName + "::_Undo(context) is not defined!");
   return false;
}

class FindBestTruckEngineAction extends Action
{
  function Name(context);
  function _Do(context);
  function _Undo(context);

  static function _EngineEval(engineId);
}

function FindBestTruckEngineAction::Name(context)
{
  return "Finding best truck engine for " + AICargo.GetCargoLabel(context.cargoId);
}

function FindBestTruckEngineAction::_EngineEval(engineId)
{
  return AIEngine.GetMaxSpeed(engineId) * AIEngine.GetCapacity(engineId) * AIEngine.GetReliability(engineId);
}

function FindBestTruckEngineAction::_Do(context)
{
  local engines = AIEngineList(AIVehicle.VT_ROAD);
  engines.Valuate(AIEngine.GetRoadType);
  engines.KeepValue(AIRoad.ROADTYPE_ROAD); // no trams
  engines.Valuate(AIEngine.IsBuildable);
  engines.KeepValue(1);
  engines.Valuate(AIEngine.CanRefitCargo, context.cargoId);
  engines.KeepValue(1);
  if (engines.IsEmpty())
  {
    AILog.Warning("Cannot find any engine for " + AICargo.GetCargoLabel(context.cargoId);
    return false;
  }

  engines.Valuate(_EngineEval);
  context.engineId <- engines.Begin();
  return true;
}

function FindBestTruckEngineAction::_Undo(context)
{
}

enum EndpointType
{
  Producer,
  Consumer
}

class ProvideStationAction
{
  constructor(industryId, cargoId, industryTileString, endpointType);
  
  function Name(context);
  function _Do(context);
  function _Undo(context);

  function FindStationTileNearIndustry();
  function BuildStation(stationTile, pathTile, roadVehicleType, stationName);

  local industryId;
  local cargoId;
  local industryTileString;
}

ProvideStationAction::constructor(industryId, cargoId, industryTileString, endpointType)
{
  this.industryId = industryId;
  this.cargoId = cargoId;
  this.industryTileString = industryTileString;
  this.endpointType = endpointType;
}
  
function ProvideStationAction::Name(context)
{
  return "Providing road station near " + AIIndustry.GetName(industryId) + " for " + AICargo.GetCargoLabel(cargoId);
}

function ProvideStationAction::FindStationTileNearIndustry()
{
  const KRAI_STATION_RADIUS = 3;
  local constr = (endpointType == EndpointType.Producer ? AITileList_IndustryProducing : AITileList_IndustryAccepting);
  local stationTiles = constr(industryId, KRAI_STATION_RADIUS);
  stationTiles.Valuate(AITile.IsBuildable);
  stationTiles.KeepValue(1);
  stationTiles.Valuate(SuperLib.Tile.IsBuildOnSlope_FlatForTerminusInDirection, SuperLib.Direction.DIR_SE);
  stationTiles.KeepValue(1);
  if (stationTiles.IsEmpty())
  {
    AILog.Warning("No suitable tiles to build a road station near " + AIIndustry.GetName(industryId));
    return false;
  }
  return stationTiles.Begin();
}

function ProvideStationAction::BuildStation(stationTile, pathTile, roadVehicleType, stationName)
{
  local succeeded = AIRoad.BuildRoadStation(stationTile, pathTile, roadVehicleType, AIStation.STATION_NEW);
  if (!succeeded)
  {
    AILog.Error("Building a station '" + stationName + "' at (" + SuperLib.Tile.GetTileString(stationTile) + ") failed: " + AIError.GetLastErrorString());
    return false;
  }
  local stationId = AIStation.GetStationId(stationTile);
  AIStation.SetName(stationId, stationName);
  return true;
}

function ProvideStationAction::_Do(context)
{
  local stationTile = FindStationTileNearIndustry();
  if (false == stationTile1) return false;
  local pathTile = stationTile + AIMap.GetTileIndex(0, 1);
  local roadVehicleType = AIRoad.GetRoadVehicleTypeForCargo(cargoId);
  local pickupStationName = AIIndustry.GetName(industryId) + " " + AICargo.GetCargoLabel(cargoId) + " PICKUP";
  if (false == BuildStation(stationTile, pathTile, roadVehicleType, pickupStationName))
  {
    return false;
  }
}

function ProvideStationAction::_Undo(context)
{
}
