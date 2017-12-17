require("Action.nut")
import("pathfinder.road", "RoadPathFinder", 3);
//import("util.superlib", "SuperLib", 40);

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

  static function _PrintRoadBuildError(tileA, tileB, entityName);

  producerTileKey = "";
  consumerTileKey = "";
}

function FindAndBuildRoadAction::Name(context)
{
  return "Finding/building road between " + context.rawget(this.producerTileKey) + " and " + context.rawget(this.consumerTileKey);
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
  //pathfinder.SetMaxIterations(20000);

  local path = false;
  //local iteration = 1;
  //local iterationsPerTick = 100;
  while (path == false) {
    //AILog.Info("Pathfinding iteration " + iteration);
    //AILog.Info("Before iteration: we are at tick " + AIController.GetTick());
    path = pathfinder.FindPath(100);
    AIController.Sleep(1);
    //iteration += iterationsPerTick;
  }
  AILog.Info("Found path!");

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
}

function FindAndBuildRoadAction::_Undo(context)
{
}

function FindAndBuildRoadAction::_PrintRoadBuildError(tileA, tileB, entityName)
{
  if (AIError.GetLastError() != AIError.ERR_ALREADY_BUILT)
  {
    AILog.Error("Cannot build " + entityName + " between " + SuperLib.Tile.GetTileString(tileA) + " and " +
        SuperLib.Tile.GetTileString(tileB) + ": " + AIError.GetLastErrorString());
  }
}

