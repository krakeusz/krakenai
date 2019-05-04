require("BfsRoadPathfinder.nut")
require("RoadHelpers.nut")
require("TruckOrders.nut")

import("util.superlib", "SuperLib", 40);

class BackgroundTaskWorker
{
  function Run();

  function _IncomingPickupTrucks(stationId); // -> AIVehicleList
  function _AdjustVehicleCounts();
  function _AdjustVehicleCountStation(stationId, cargoId);
  function _BuyNewVehiclesIfNeeded(stationId, cargoId);
  function _SendVehiclesToDepotIfNeeded(stationId, cargoId);
  function _FindNearestDepot(stationId);
  function _CapacitiesIncomingTrucks(stationId, cargoId);
  function _PredictedMonthlySupply(stationId, cargoId);
  function _CloneAndStartVehicle(templateTruck, templateGroup, depotLocation);
  function _GetSupplierIndustries(stationId, cargoId);
  function _SumValues(aiList);

  isRunning = false;
}

function BackgroundTaskWorker::Run()
{
  if (isRunning) { return; } // could recurse, we don't want that
  isRunning = true;
  AILog.Info("Processing some background tasks.");
  try
  {
    _AdjustVehicleCounts();
    _SellVehiclesInDepots();
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

function BackgroundTaskWorker::_SellVehiclesInDepots()
{
  local vehicles = AIVehicleList();
  vehicles.Valuate(AIVehicle.GetVehicleType);
  vehicles.KeepValue(AIVehicle.VT_ROAD);

  vehicles.Valuate(AIVehicle.GetState);
  vehicles.KeepValue(AIVehicle.VS_IN_DEPOT);
  
  for (local vehicleId = vehicles.Begin(); !vehicles.IsEnd(); vehicleId = vehicles.Next())
  {
    AILog.Info("Selling a vehicle from group " + AIGroup.GetName(AIVehicle.GetGroupID(vehicleId)));
    AIVehicle.SellVehicle(vehicleId);
  }
}

function BackgroundTaskWorker::_BuyNewVehiclesIfNeeded(stationId, cargoId)
{
  local cargoWaiting = AIStation.GetCargoWaiting(stationId, cargoId);
  if (cargoWaiting < 50) { return; }
  if (_CapacitiesIncomingTrucks(stationId, cargoId) > 0.2 * _PredictedMonthlySupply(stationId, cargoId)) { return; }

  local otherTrucks = AIVehicleList_Station(stationId);
  local templateTruck = otherTrucks.Begin();
  local templateEngine = AIVehicle.GetEngineType(templateTruck);
  local capacity = AIEngine.GetCapacity(templateEngine);
  local templateGroup = AIVehicle.GetGroupID(templateTruck);
  local depotLocation = _FindNearestDepot(stationId);
  if (depotLocation == null)
  {
    AILog.Warning("Cannot find any depots near station " + AIStation.GetName(stationId) + ". This is probably a bug.");
    return;
  }
  _CloneAndStartVehicle(templateTruck, templateGroup, depotLocation);
  AILog.Info("Cloned a truck for station " + AIStation.GetName(stationId));
}

function BackgroundTaskWorker::_SendVehiclesToDepotIfNeeded(stationId, cargoId)
{
  local cargoWaiting = AIStation.GetCargoWaiting(stationId, cargoId);
  if (cargoWaiting > 0) { return; }
  if (_CapacitiesIncomingTrucks(stationId, cargoId) < 0.6 * _PredictedMonthlySupply(stationId, cargoId)) { return; }
  local trucks = _IncomingPickupTrucks(stationId);
  if (trucks.Count() < 2) { return; }

  // Send only empty trucks to depot
  trucks.Valuate(AIVehicle.GetCargoLoad, cargoId);
  trucks.RemoveAboveValue(0);
  if (trucks.IsEmpty()) { return; }
  
  local truckToStop = trucks.Begin();
  TruckOrders.StopInDepot(truckToStop);
  AILog.Info("Sent truck " + truckToStop + " to stop in depot, for station " + AIStation.GetName(stationId));
}

function BackgroundTaskWorker::_AdjustVehicleCountStation(stationId, cargoId)
{
  _BuyNewVehiclesIfNeeded(stationId, cargoId);
  _SendVehiclesToDepotIfNeeded(stationId, cargoId);
}

// Return id of nearest depot's tile (BFS search over roads), or null if not found
function BackgroundTaskWorker::_FindNearestDepot(stationId)
{
  local depots = AIDepotList(AITile.TRANSPORT_ROAD);
  local MAX_SEARCH_DISTANCE = 10;
  return BfsRoadPathfinder.Find(AIStation.GetLocation(stationId), depots, MAX_SEARCH_DISTANCE);
}

function BackgroundTaskWorker::_CloneAndStartVehicle(templateVehicle, templateGroup, depotLocation)
{
  local vehicleId = RoadHelpers.CloneRoadVehicle(depotLocation, templateVehicle);
  AIGroup.MoveVehicle(templateGroup, vehicleId);
  AIVehicle.StartStopVehicle(vehicleId);
}

function BackgroundTaskWorker::_CapacitiesIncomingTrucks(stationId, cargoId)
{
  local trucks = _IncomingPickupTrucks(stationId);
  trucks.Valuate(AIVehicle.GetCapacity, cargoId);
  return _SumValues(trucks);
}

// Get the list of vehicles that are loading at the station or will load in the near future.
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
  vehicles.KeepValue(TruckOrders.PICKUP_ORDER);

  vehicles.Valuate(AIVehicle.GetState);
  vehicles.RemoveValue(AIVehicle.VS_STOPPED);
  vehicles.RemoveValue(AIVehicle.VS_IN_DEPOT);
  vehicles.RemoveValue(AIVehicle.VS_CRASHED);
  vehicles.RemoveValue(AIVehicle.VS_BROKEN);
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

// Return list of all industries that produce given cargo and are in covered by given station's pickup range.
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
