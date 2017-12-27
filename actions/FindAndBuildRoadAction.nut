require("Action.nut")
require("../BackgroundTask.nut")
require("../RoadHelpers.nut")
import("pathfinder.road", "RoadPathFinder", 3);

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
  local pathfinder = RoadPathFinder();
  local producerTile = context.rawget(this.producerTileKey);
  local consumerTile = context.rawget(this.consumerTileKey);
  AILog.Info("Finding path...");
  pathfinder.InitializePath([producerTile], [consumerTile]);
  pathfinder.cost.slope = 50;

  local path = false;
  while (path == false) {
    path = pathfinder.FindPath(200);
    BackgroundTask.Run();
    AIController.Sleep(1);
  }
  AILog.Info("Found path!");

  while (path != null) {
    local par = path.GetParent();
    if (par != null) {
      local last_node = path.GetTile();
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        RoadHelpers.BuildRoad(path.GetTile(), par.GetTile());
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
              /* An error occured while building a tunnel. */
              RoadHelpers.PrintRoadBuildError(path.GetTile(), par.GetTile(), "tunnel");
            }
          } else {
            local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
            bridge_list.Valuate(AIBridge.GetMaxSpeed);
            bridge_list.Sort(AIList.SORT_BY_VALUE, false);
            if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
              /* An error occured while building a bridge. */
              RoadHelpers.PrintRoadBuildError(path.GetTile(), par.GetTile(), "bridge");
            }
          }
        }
      }
    }
    path = par;
  }
}

function FindAndBuildRoadAction::_Undo(context)
{
}

