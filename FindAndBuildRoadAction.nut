require("Action.nut")
require("RoadHelpers.nut")
//import("pathfinder.road", "RoadPathFinder", 3);
import("util.superlib", "SuperLib", 40)

class FindAndBuildRoadAction extends Action
{
  constructor(context, producerTileKey, consumerTileKey)
  {
    ::Action.constructor();
    this.producerTileKey = producerTileKey;
    this.consumerTileKey = consumerTileKey;
  }
  function Name(context);
  function _Do(context);
  function _Undo(context);


  producerTileKey = "";
  consumerTileKey = "";
}

function FindAndBuildRoadAction::Name(context)
{
  return "Finding/building road between " + SuperLib.Tile.GetTileString(context.rawget(this.producerTileKey)) +
         " and " + SuperLib.Tile.GetTileString(context.rawget(this.consumerTileKey));
}

function FindAndBuildRoadAction::_Do(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local pathfinder = SuperLib.RoadPathFinder();
  local producerTile = context.rawget(this.producerTileKey);
  local consumerTile = context.rawget(this.consumerTileKey);
  local restartsLeft = 3;
  local restart = false;
  do
  {
    restart = false;
    AILog.Info("Finding path...");
    pathfinder.InitializePath([producerTile], [consumerTile], false, [], 2);

    local path = null;
    while (path == null) 
    {
      path = pathfinder.FindPath(200);
      local error = pathfinder.GetFindPathError();
      if (error != SuperLib.RoadPathFinder.PATH_FIND_NO_ERROR)
      {
        throw "Cannot find path between two stations: " + error;
      }
      KrakenAI.BackgroundTask.Run();
      AIController.Sleep(1);
    }
    AILog.Info("Found path!");

    while (path != null)
    {
      local par = path.GetParent();
      try
      {
        if (par != null)
        {
          local last_node = path.GetTile();
          if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 )
          {
            RoadHelpers.BuildRoad(path.GetTile(), par.GetTile());
          }
          else
          {
            /* Build a bridge or tunnel. */
            if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile()))
            {
              /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
              if (AIRoad.IsRoadTile(path.GetTile()))
              {
                AITile.DemolishTile(path.GetTile());
              }
              if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile())
              {
                RoadHelpers.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile(), par.GetTile());
              }
              else
              {
                local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
                bridge_list.Valuate(AIBridge.GetMaxSpeed);
                bridge_list.Sort(AIList.SORT_BY_VALUE, false);
                RoadHelpers.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile());
              }
            }
          }
        }
      }
      catch (ex)
      {
        AILog.Warning(ex);
        restart = true;
      }
      path = par;
    }
  }
  while (restart && restartsLeft-- > 0);
}

function FindAndBuildRoadAction::_Undo(context)
{
}

