require("Action.nut")
require("../pathfinders/HogExRoadPathfinder.nut")
require("../road_helpers/RoadHelpers.nut")
import("util.superlib", "SuperLib", 40)

class FindAndBuildRoadAction extends Action
{
  constructor(context, producerTileKey, consumerTileKey, engineId)
  {
    ::Action.constructor();
    this.producerTileKey = producerTileKey;
    this.consumerTileKey = consumerTileKey;
    this.engineId = engineId;
  }
  function Name(context);
  function _Do(context);
  function _Undo(context);


  producerTileKey = "";
  consumerTileKey = "";
  engineId = null;
}

function FindAndBuildRoadAction::Name(context)
{
  return "Finding/building road between " + SuperLib.Tile.GetTileString(context.rawget(this.producerTileKey)) +
         " and " + SuperLib.Tile.GetTileString(context.rawget(this.consumerTileKey));
}

function FindAndBuildRoadAction::_FindPath(context, pathfinder)
{
  local producerTile = context.rawget(this.producerTileKey);
  local consumerTile = context.rawget(this.consumerTileKey);
  pathfinder.InitializePath([producerTile], [consumerTile], []);

  local path = false;
  while (path == false) 
  {
    AILog.Info("Searching for path...");
    path = pathfinder.FindPath(200);
    KrakenAI.BackgroundTask.Run();
  }
  if (path != null && path != false) {
    AILog.Info("Found path!");
  } else {
    path = null;
    AILog.Warning("Path could not be found.");
  }
  return path;
}

function FindAndBuildRoadAction::_BuildPath(context, path)
{
  if (path == null) {
    return false;
  }
  
  local execMode = AIExecMode();
  local currentRoadType = AIRoad.GetCurrentRoadType();
  local maxSpeed = AIRoad.GetMaxSpeed(currentRoadType);
  local par;
  
  for (; path != null; path = par) {
    par = path.GetParent();
    if (par != null) {
      local pathTile = path.GetTile();
      local parTile = par.GetTile();
      local distance = AIMap.DistanceManhattan(pathTile, parTile);
      
      // Handle existing bridges/tunnels
      local isBridgeOrTunnel = AIBridge.IsBridgeTile(pathTile) || AITunnel.IsTunnelTile(pathTile);
      if (isBridgeOrTunnel) {
        local roadType = this._GetTileRoadType(pathTile);
        if (roadType != null && AIRoad.RoadVehHasPowerOnRoad(currentRoadType, roadType)) {
          local end = AIBridge.IsBridgeTile(pathTile)
            ? AIBridge.GetOtherBridgeEnd(pathTile) 
            : AITunnel.GetOtherTunnelEnd(pathTile);
          if (end == parTile) {
            continue; // Reuse existing bridge/tunnel
          }
        }
      }
      
      // Handle adjacent tiles (build or convert roads)
      if (distance == 1) {
        RoadHelpers.WaitForFundsWithMargin(1000);
        local connected = AIRoad.AreRoadTilesConnected(pathTile, parTile);
        
        if (connected) {
          local roadType = this._GetTileRoadType(pathTile);
          if (roadType != null) {
            local localMaxSpeed = AIRoad.GetMaxSpeed(roadType);
            if (localMaxSpeed != 0 && (localMaxSpeed < maxSpeed || maxSpeed == 0)) {
              if (!AIRoad.ConvertRoadType(pathTile, parTile, currentRoadType)) {
                AILog.Warning("ConvertRoadType failed: " + AIError.GetLastErrorString());
              }
            }
          }
          continue;
        }
        
        // Build road between adjacent tiles
        local builtRoad = this._BuildRoadUntilFree(pathTile, parTile);
        local error = AIError.GetLastError();
        
        if (!builtRoad && error != AIError.ERR_ALREADY_BUILT) {
          if (error == AIError.ERR_AREA_NOT_CLEAR) {
            if (AICompany.IsMine(AITile.GetOwner(parTile))) {
              AILog.Warning("BuildRoad failed - area not clear at own tile: " + AIError.GetLastErrorString());
              return false;
            }
            AILog.Warning("Attempting to demolish tile: " + AIError.GetLastErrorString());
            RoadHelpers.WaitForFundsWithMargin(2000);
            if (!AITile.DemolishTile(parTile)) {
              AILog.Warning("DemolishTile failed: " + AIError.GetLastErrorString());
            }
            builtRoad = this._BuildRoadUntilFree(pathTile, parTile);
          }
          
          if (!builtRoad) {
            AILog.Warning("BuildRoad failed: " + AIError.GetLastErrorString());
            return false;
          }
        }
      } else {
        // Handle non-adjacent tiles (bridges/tunnels)
        if (!isBridgeOrTunnel && AIRoad.IsRoadTile(pathTile) && !AITile.IsStationTile(pathTile)) {
          AITile.DemolishTile(pathTile);
        }
        
        if (AITunnel.GetOtherTunnelEnd(pathTile) == parTile) {
          AILog.Warning("Building a tunnel!");
          RoadHelpers.WaitForFundsWithMargin(50000);
          RoadHelpers.BuildTunnel(AIVehicle.VT_ROAD, pathTile, parTile);
        } else {
          local bridge_list = AIBridgeList_Length(distance + 1);
          bridge_list.Valuate(AIBridge.GetMaxSpeed);
          bridge_list.Sort(AIList.SORT_BY_VALUE, false);
          RoadHelpers.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), pathTile, parTile);
        }
      }
    }
  }
  
  AILog.Info("BuildPath succeeded");
  return true;
}

function FindAndBuildRoadAction::_GetTileRoadType(tile)
{
  // For trucks/buses, only check regular roads (not trams)
  local roadTypes = AIRoadTypeList(AIRoad.ROADTRAMTYPES_ROAD);
  foreach(roadType, _ in roadTypes) {
    if (AIRoad.HasRoadType(tile, roadType)) {
      return roadType;
    }
  }
  return null;
}

function FindAndBuildRoadAction::_BuildRoadUntilFree(fromTile, toTile)
{
  // Try to build road, retrying multiple times if area is not clear
  for (local attempt = 0; attempt < 10; attempt++) {
    if (AIRoad.BuildRoad(fromTile, toTile)) {
      return true;
    }
    
    local error = AIError.GetLastError();
    if (error != AIError.ERR_AREA_NOT_CLEAR) {
      // Stop retrying for non-temporary errors
      return false;
    }
    
    // Wait and retry
    KrakenAI.BackgroundTask.Run();
  }
  
  return false;
}

function FindAndBuildRoadAction::_Do(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local pathfinder = HogExRoadPathFinder();
  pathfinder.engine = this.engineId;
  local restartsLeft = 3;
  local restart = false;
  
  do {
    restart = false;
    local path = this._FindPath(context, pathfinder);
    
    if (!this._BuildPath(context, path)) {
      if (restartsLeft > 0) {
        AILog.Warning("BuildPath failed, retrying...");
        restart = true;
      } else {
        AILog.Error("BuildPath failed after all retries");
        return false;
      }
    }
  } while (restart && restartsLeft-- > 0);
  
  return true;
}

function FindAndBuildRoadAction::_Undo(context)
{
}

