import("util.superlib", "SuperLib", 40);
require("tile.nut");

class RoadConnection
{
  function Build();

  static function _IndustryBestEval(industryId);
  static function _IndustryBestCargo(industryId);
  static function _IndustryBestCargoAndEval(industryId);
  static function _IndustryManhattanDistanceToCircle(industryId, circleRadius, centerTile);
  static function _FindBestProducerId();
  static function _FindStationTileNearIndustry(industryId);
  static function _BuildStation(stationTile, roadVehicleType, stationName);
  static function _FindAndBuildPath(tileA, tileB);
  static function _PrintRoadBuildError(tileA, tileB, entityName);
  static function _EngineEval(engineId);
  static function _BuyAndStartVehicles(depotTile, engineId, cargoId, stationTile1, stationTile2, nVehicles);
}

enum EndpointType
{
  Producer,
  Consumer
}

function RoadConnection::_IndustryBestCargoAndEval(industryId)
{
  // Find the cargo which this industry produces and is "most profitable"
  local cargos = AICargoList_IndustryProducing(industryId);
  // Exclude cargos which no trucks can carry
  cargos.Valuate(SuperLib.Engine.DoesEngineExistForCargo, AIVehicle.VT_ROAD);
  cargos.KeepValue(1);
  local bestCargoId = -1;
  local bestEval = 0;
  local AVG_DISTANCE = 50;
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

function RoadConnection::_IndustryBestEval(industryId)
{
  return RoadConnection._IndustryBestCargoAndEval(industryId).eval;
}

function RoadConnection::_IndustryBestCargo(industryId)
{
  return RoadConnection._IndustryBestCargoAndEval(industryId).cargoId;
}

function RoadConnection::_IndustryManhattanDistanceToCircle(industryId, circleRadius, centerTile)
{
  local distToIndustry = AIIndustry.GetDistanceManhattanToTile(industryId, centerTile);
  return abs(circleRadius - distToIndustry);
}

function RoadConnection::_BuildStation(stationTile, roadVehicleType, stationName)
{
  local succeeded = AIRoad.BuildRoadStation(stationTile, stationTile + AIMap.GetTileIndex(0, 1), roadVehicleType, AIStation.STATION_NEW);
  if (!succeeded)
  {
    AILog.Error("Building a station '" + stationName + "' at (" + AIMap.GetTileX(stationTile) + ", " + AIMap.GetTileY(stationTile) + ") failed: " + AIError.GetLastErrorString());
    return null;
  }
  return 1;
}

function RoadConnection::_FindBestProducerId()
{
  local industries = AIIndustryList();
  industries.Valuate(AIIndustry.GetAmountOfStationsAround); // TODO: consider multi-producing industries and so on
  industries.KeepValue(0);
  if (industries.IsEmpty())
  {
    AILog.Warning("No unserviced industries left, no action taken!");
    return null;
  }
  industries.Valuate(RoadConnection._IndustryBestEval);
  industries.KeepAboveValue(0);
  if (industries.IsEmpty())
  {
    AILog.Warning("No industries left that produced anything last month, no action taken!");
    return null;
  }
  return industries.Begin();
}

function RoadConnection::_FindStationTileNearIndustry(industryId, endpointType)
{
  local STATION_RADIUS = 3;
  local constr = (endpointType == EndpointType.Producer ? AITileList_IndustryProducing : AITileList_IndustryAccepting);
  local stationTiles = constr(industryId, STATION_RADIUS);
  stationTiles.Valuate(AITile.IsBuildable);
  stationTiles.KeepValue(1);
  stationTiles.Valuate(SuperLib.Tile.IsBuildOnSlope_FlatForTerminusInDirection, SuperLib.Direction.DIR_SE);
  stationTiles.KeepValue(1);
  if (stationTiles.IsEmpty())
  {
    AILog.Warning("No suitable tiles to build a road station near " + AIIndustry.GetName(industryId));
    return null;
  }
  return stationTiles.Begin();
}

function RoadConnection::_FindAndBuildPath(tileA, tileB)
{
  local pathfinder = SuperLib.RoadPathFinder();
  pathfinder.InitializePath([tileA], [tileB]);
  pathfinder.SetMaxIterations(20000);

  local path = null;
  local iteration = 1;
  local iterationsPerTick = 1000;
  while (path == null) {
    AILog.Info("Pathfinding iteration " + iteration);
    AILog.Info("Before iteration: we are at tick " + AIController.GetTick());
    path = pathfinder.FindPath(iterationsPerTick);
    local error = pathfinder.GetFindPathError();
    if (error != SuperLib.RoadPathFinder.PATH_FIND_NO_ERROR)
    {
      AILog.Error("Cannot find path between two stations: " + error);
      return null;
    }
    AILog.Info("After iteration: we are at tick " + AIController.GetTick());
    AIController.Sleep(1);
    iteration += iterationsPerTick;
  }

  while (path != null) {
    local par = path.GetParent();
    if (par != null) {
      local last_node = path.GetTile();
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          /* An error occurred while building a piece of road.
           * Note that this could mean the road was already built. */
          _PrintRoadBuildError(path.GetTile(), par.GetTile(), "road segment");
        }
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
              /* An error occured while building a tunnel. */
              _PrintRoadBuildError(path.GetTile(), par.GetTile(), "tunnel");
            }
          } else {
            local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
            bridge_list.Valuate(AIBridge.GetMaxSpeed);
            bridge_list.Sort(AIList.SORT_BY_VALUE, false);
            if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
              /* An error occured while building a bridge. */
              _PrintRoadBuildError(path.GetTile(), par.GetTile(), "bridge");
            }
          }
        }
      }
    }
    path = par;
  }
  return 1;
}

function RoadConnection::_PrintRoadBuildError(tileA, tileB, entityName)
{
  AILog.Error("Cannot build " + entityName + " between " + SuperLib.Tile.GetTileString(tileA) + " and " +
              SuperLib.Tile.GetTileString(tileB) + ": " + AIError.GetLastErrorString());
}

function RoadConnection::_FindBestTruckFor(producerId, cargoId)
{
  local engines = AIEngineList(AIVehicle.VT_ROAD);
  engines.Valuate(AIEngine.GetRoadType);
  engines.KeepValue(AIRoad.ROADTYPE_ROAD); // no trams
  engines.Valuate(AIEngine.IsBuildable);
  engines.KeepValue(1);
  engines.Valuate(AIEngine.CanRefitCargo, cargoId);
  engines.KeepValue(1);
  if (engines.IsEmpty()) return null;

  engines.Valuate(_EngineEval);
  return engines.Begin();
}

function RoadConnection::_EngineEval(engineId)
{
  return AIEngine.GetMaxSpeed(engineId) * AIEngine.GetCapacity(engineId) * AIEngine.GetReliability(engineId);
}

function RoadConnection::_BuyAndStartVehicles(depotTile, engineId, cargoId, stationTile1, stationTile2, nVehicles)
{
  for (local i = 0; i < nVehicles; i++)
  {
    local vehicleId = AIVehicle.BuildVehicle(depotTile, engineId);
    if (!AIVehicle.IsValidVehicle(vehicleId))
    {
      AILog.Error("Cannot build vehicle " + AIEngine.GetName(engineId) + ": " + AIError.GetLastErrorString());
      return null;
    }
    if (!AIVehicle.RefitVehicle(vehicleId, cargoId)) {
      AILog.Error("Cannot refit vehicle " + AIEngine.GetName(engineId) + " to cargo " + AICargo.GetCargoLabel(cargoId));
      AIVehicle.SellVehicle(vehicleId);
      return null;
    }
    AIOrder.AppendOrder(vehicleId, stationTile1, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
    AIOrder.AppendOrder(vehicleId, stationTile2, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_UNLOAD);
    AIOrder.AppendOrder(vehicleId, depotTile, AIOrder.OF_SERVICE_IF_NEEDED | AIOrder.OF_NON_STOP_INTERMEDIATE);
    AIVehicle.StartStopVehicle(vehicleId);
  }
  return true;
}

function RoadConnection::Build()
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  local bestProducerId = _FindBestProducerId();
  if (bestProducerId == null) return;

  local bestCargoId = RoadConnection._IndustryBestCargo(bestProducerId);
  local bestCargoName = AICargo.GetCargoLabel(bestCargoId);
  AILog.Info("The best cargo to carry now is " + bestCargoName);
  AILog.Info("The best industry producing " + bestCargoName + " is " + AIIndustry.GetName(bestProducerId));

  local stationTile1 = _FindStationTileNearIndustry(bestProducerId, EndpointType.Producer);
  if (stationTile1 == null) return;
  local pathTile1 = stationTile1 + AIMap.GetTileIndex(0, 1);

  local roadVehicleType = AIRoad.GetRoadVehicleTypeForCargo(bestCargoId);
  local pickupStationName = AIIndustry.GetName(bestProducerId) + " " + AICargo.GetCargoLabel(bestCargoId) + " PICKUP";
  if (null == _BuildStation(stationTile1, roadVehicleType, pickupStationName))
  {
    return;
  }

  local acceptingIndustries = AIIndustryList_CargoAccepting(bestCargoId);
  if (acceptingIndustries.IsEmpty())
  {
    AILog.Warning("No industries accepting " + bestCargoName + "! Abandoning the project.");
    return;
  }
  local BEST_DISTANCE_TO_DROP = 50;
  acceptingIndustries.Valuate(_IndustryManhattanDistanceToCircle, BEST_DISTANCE_TO_DROP, stationTile1);
  acceptingIndustries.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
  local bestConsumerId = acceptingIndustries.Begin();
  AILog.Info("The best industry accepting " + bestCargoName + " is " + AIIndustry.GetName(bestConsumerId));

  local stationTile2 = _FindStationTileNearIndustry(bestConsumerId, EndpointType.Consumer);
  if (stationTile2 == null) return;
  local pathTile2 = stationTile2 + AIMap.GetTileIndex(0, 1);

  local dropStationName = AIIndustry.GetName(bestConsumerId) + " " + AICargo.GetCargoLabel(bestCargoId) + " DROP";
  if (null == _BuildStation(stationTile2, roadVehicleType, dropStationName))
  {
    return;
  }
  AIRoad.BuildRoad(stationTile1, pathTile1);
  AIRoad.BuildRoad(stationTile2, pathTile2);
  if (null == _FindAndBuildPath(pathTile1, pathTile2))
  {
    return;
  }
  local depotTile = SuperLib.Road.BuildDepotNextToRoad(pathTile1, 1, 20);
  if (null == depotTile) return;

  local bestEngineId = _FindBestTruckFor(bestProducerId, bestCargoId);
  if (null == bestEngineId)
  {
    AILog.Error("No engines found for " + bestCargoName + "!");
    return;
  }
  AILog.Info("Best engine for " + bestCargoName + " is " + AIEngine.GetName(bestEngineId));

  local nVehicles = 1.0 * AIIndustry.GetLastMonthProduction(bestProducerId, bestCargoId) / AIEngine.GetCapacity(bestEngineId) * AIIndustry.GetDistanceManhattanToTile(bestProducerId, stationTile2) / 50 + 1;
  if (null == _BuyAndStartVehicles(depotTile, bestEngineId, bestCargoId, stationTile1, stationTile2, nVehicles))
  {
    AILog.Error("Could not buy/start vehicles!");
    return;
  }
  AILog.Info("Everything OK!");
}
