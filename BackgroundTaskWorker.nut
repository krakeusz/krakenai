require("RoadHelpers.nut")

import("util.superlib", "SuperLib", 40);

class BackgroundTaskWorker
{
  function _Run();

  function _IncomingPickupTrucks(stationId); // -> AIVehicleList
  function _AdjustVehicleCounts();
  function _AdjustVehicleCountStation(stationId, cargoId);
  function _FindNearestDepot(stationId);
  function _CapacitiesIncomingTrucks(stationId, cargoId);
  function _PredictedMonthlySupply(stationId, cargoId);
  function _CloneAndStartVehicle(templateTruck, templateGroup, depotLocation);
  function _GetSupplierIndustries(stationId, cargoId);
  function _SumValues(aiList);

  isRunning = false;
}

function BackgroundTaskWorker::_Run()
{
  if (isRunning) { return; } // could recurse, we don't want that
  isRunning = true;
  AILog.Info("BackgroundTaskWorker::_Run()");
  try
  {
    _AdjustVehicleCounts();
  }
  catch (exceptionString)
  {
    AILog.Error("Cannot do background task: " + exceptionString);
  }
  isRunning = false;
}

function BackgroundTaskWorker::_AdjustVehicleCounts()
{
  local myStations = AIStationList(AIStation.STATION_ANY);
  myStations.Valuate(AIStation.HasRoadType, AIRoad.ROADTYPE_ROAD);
  myStations.KeepValue(1);
  for (local stationId = myStations.Begin(); !myStations.IsEnd(); stationId = myStations.Next())
  {
    local cargos = AICargoList();
    for (local cargoId = cargos.Begin(); !cargos.IsEnd(); cargoId = cargos.Next())
    {
      if (AIStation.HasCargoRating(stationId, cargoId))
      {
        _AdjustVehicleCountStation(stationId, cargoId);
      }
    }
  }
}

function BackgroundTaskWorker::_AdjustVehicleCountStation(stationId, cargoId)
{
  local cargoWaiting = AIStation.GetCargoWaiting(stationId, cargoId);
  if (cargoWaiting < 50) { return; }
  if (_CapacitiesIncomingTrucks(stationId, cargoId) > 0.3 * _PredictedMonthlySupply(stationId, cargoId)) { return; }

  local otherTrucks = AIVehicleList_Station(stationId);
  local templateTruck = otherTrucks.Begin();
  local templateEngine = AIVehicle.GetEngineType(templateTruck);
  local capacity = AIEngine.GetCapacity(templateEngine);
  local templateGroup = AIVehicle.GetGroupID(templateTruck);
  local depotLocation = _FindNearestDepot(stationId);
  _CloneAndStartVehicle(templateTruck, templateGroup, depotLocation);
  AILog.Info("Cloned a truck for station " + AIStation.GetName(stationId));
}

function BackgroundTaskWorker::_FindNearestDepot(stationId)
{
  local depots = AIDepotList(AITile.TRANSPORT_ROAD);
  depots.Valuate(AITile.GetDistanceManhattanToTile, AIStation.GetLocation(stationId));
  depots.KeepBottom(1);
  return depots.Begin();
}

function BackgroundTaskWorker::_CloneAndStartVehicle(templateVehicle, templateGroup, depotLocation)
{
  local vehicleId = RoadHelpers.CloneTruck(depotLocation, templateVehicle);
  AIGroup.MoveVehicle(templateGroup, vehicleId);
  AIVehicle.StartStopVehicle(vehicleId);
}

function BackgroundTaskWorker::_CapacitiesIncomingTrucks(stationId, cargoId)
{
  local trucks = _IncomingPickupTrucks(stationId);
  trucks.Valuate(AIVehicle.GetCapacity, cargoId);
  return _SumValues(trucks);
}

function BackgroundTaskWorker::_IncomingPickupTrucks(stationId)
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

  vehicles.Valuate(AIOrder.ResolveOrderPosition, AIOrder.ORDER_CURRENT);
  // Assuming that first order is pickup order
  vehicles.KeepValue(0);
  return vehicles;
}

function BackgroundTaskWorker::_PredictedMonthlySupply(stationId, cargoId)
{
  local suppliers = _GetSupplierIndustries(stationId, cargoId);
  suppliers.Valuate(AIIndustry.GetLastMonthProduction, cargoId);
  return _SumValues(suppliers);
}

function BackgroundTaskWorker::_SumValues(aiList)
{
  local sum = 0;
  for (local item = aiList.Begin(); !aiList.IsEnd(); item = aiList.Next())
  {
    sum = sum + aiList.GetValue(item);
  }
  return sum;
}

function BackgroundTaskWorker::_GetSupplierIndustries(stationId, cargoId)
{
  local industries = AIIndustryList_CargoProducing(cargoId);
  local isCargoSupplied = function(industryId, stationId, cargoId)
  {
    return SuperLib.Station.IsCargoSuppliedByIndustry(stationId, cargoId, industryId);
  };
  industries.Valuate(isCargoSupplied, stationId, cargoId);
  industries.KeepValue(1);
  return industries;
}

class IndustriesCargoStation
{
  constructor() { industryIds = {}; }
  industryIds = null;
  cargoId = -1;
  stationId = -1;
}
