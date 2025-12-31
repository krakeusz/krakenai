require("pathfinders/BfsRoadPathfinder.nut")
require("road_helpers/RoadHelpers.nut")
require("road_helpers/TruckOrders.nut")

import("util.superlib", "SuperLib", 40);

// Calling Run() will process some short tasks that shouldn't take too long, but should be run frequently.
// The idea is that during long tasks, like pathfinding, we want some quick actions to be done, like cloning
// buses if there is enough money. So during pathfinging, Run() should be called multiple times.
class _KrakenAI_BackgroundTask
{
  function Run();

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

function _KrakenAI_BackgroundTask::Run()
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

function _KrakenAI_BackgroundTask::_AdjustVehicleCounts()
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

function _KrakenAI_BackgroundTask::_SellVehiclesInDepots()
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

function _KrakenAI_BackgroundTask::_BuyNewVehiclesIfNeeded(stationId, cargoId)
{
  if (SuperLib.Vehicle.GetVehiclesLeft(AIVehicle.VT_ROAD) <= 0) { return; }
  local cargoWaiting = AIStation.GetCargoWaiting(stationId, cargoId);

  // if (cargoWaiting < 50) { return; }
  // if (_CapacitiesIncomingTrucks(stationId, cargoId) > 0.2 * _PredictedMonthlySupply(stationId, cargoId)) { return; }

  local otherTrucks = AIVehicleList_Station(stationId);
  local templateTruck = otherTrucks.Begin();
  local templateEngine = AIVehicle.GetEngineType(templateTruck);
  local truckCapacity = AIEngine.GetCapacity(templateEngine);
  // Use a square root or logarithm to reduce number of trucks bought at once.
  // Otherwise, if we're buying for a long time because of low funds,
  // by the time the station is empty we'll be in the middle of purchasing.
  local trucksToBuy = ceil(sqrt(cargoWaiting / truckCapacity));
  if (trucksToBuy < 1) { return; }
  
  local templateGroup = AIVehicle.GetGroupID(templateTruck);
  local depotLocation = _FindNearestDepot(stationId);
  if (depotLocation == null)
  {
    AILog.Warning("Cannot find any depots near station " + AIStation.GetName(stationId) + ". This is probably a bug.");
    return;
  }

  for (local i = 0; i < trucksToBuy; i++)
  {
    _CloneAndStartVehicle(templateTruck, templateGroup, depotLocation);
    AILog.Info("Cloned a truck for station " + AIStation.GetName(stationId));
  }
}

function _KrakenAI_BackgroundTask::_SendVehiclesToDepotIfNeeded(stationId, cargoId)
{
  // Get the percentage of vehicles which have 0 velocity and are empty. These are loading at the station.
  local trucks = AIVehicleList_Station(stationId);
  trucks.Valuate(AIVehicle.GetCurrentSpeed);
  trucks.KeepValue(0);
  trucks.Valuate(AIVehicle.GetCargoLoad, cargoId);
  trucks.RemoveAboveValue(0);
  // Exclude trucks that are already going to depot
  trucks.Valuate(TruckOrders.IsStoppingAtDepot);
  trucks.RemoveValue(1);
  if (trucks.IsEmpty()) { return; }
  AILog.Info("Station " + AIStation.GetName(stationId) + " has " + trucks.Count() + " idle loading truck(s).");
  
  local vehiclesToStop = SuperLib.Helper.Max(trucks.Count() - 6, 0); // keep some trucks at station

  for (local truckToStop = 0; truckToStop < vehiclesToStop; truckToStop++)
  {
    local truckId = trucks.GetValue(truckToStop); // Get the actual vehicleId
    TruckOrders.StopInDepot(truckId); // Use the correct vehicleId
    AILog.Info("Sent truck " + truckId + " to stop in depot, for station " + AIStation.GetName(stationId));
  }
}

function _KrakenAI_BackgroundTask::_AdjustVehicleCountStation(stationId, cargoId)
{
  _SendVehiclesToDepotIfNeeded(stationId, cargoId);
  _BuyNewVehiclesIfNeeded(stationId, cargoId);
}

// Return id of nearest depot's tile (BFS search over roads), or null if not found
function _KrakenAI_BackgroundTask::_FindNearestDepot(stationId)
{
  local depots = AIDepotList(AITile.TRANSPORT_ROAD);
  local MAX_SEARCH_DISTANCE = 10;
  return BfsRoadPathfinder.Find(AIStation.GetLocation(stationId), depots, MAX_SEARCH_DISTANCE);
}

function _KrakenAI_BackgroundTask::_CloneAndStartVehicle(templateVehicle, templateGroup, depotLocation)
{
  local vehicleId = RoadHelpers.CloneRoadVehicle(depotLocation, templateVehicle);
  AIGroup.MoveVehicle(templateGroup, vehicleId);
  AIVehicle.StartStopVehicle(vehicleId);
}

function _KrakenAI_BackgroundTask::_CapacitiesIncomingTrucks(stationId, cargoId)
{
  local trucks = RoadHelpers.IncomingTrucks(stationId);
  trucks.Valuate(AIVehicle.GetCapacity, cargoId);
  return _SumValues(trucks);
}

function _KrakenAI_BackgroundTask::_PredictedMonthlySupply(stationId, cargoId)
{
  local suppliers = _GetSupplierIndustries(stationId, cargoId);
  suppliers.Valuate(AIIndustry.GetLastMonthProduction, cargoId);
  return _SumValues(suppliers);
}

function _KrakenAI_BackgroundTask::_SumValues(aiList)
{
  local sum = 0;
  for (local item = aiList.Begin(); !aiList.IsEnd(); item = aiList.Next())
  {
    sum = sum + aiList.GetValue(item);
  }
  return sum;
}

// Return list of all industries that produce given cargo and are in covered by given station's pickup range.
function _KrakenAI_BackgroundTask::_GetSupplierIndustries(stationId, cargoId)
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
