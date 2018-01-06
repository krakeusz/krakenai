require("Action.nut")
require("../RoadHelpers.nut")

class ProvideDepotAction extends Action
{
  constructor(context, entranceTileKey, name)
  {
    ::Action.constructor();
    this.entranceTileKey = entranceTileKey;
    this.name = name;
  }
  function Name(context);

  // sets context."name"_tile to the tile of a valid (maybe new) depot
  function _Do(context);
  function _Undo(context);

  name = "";
  entranceTileKey = "";
}

function ProvideDepotAction::Name(context)
{
  return "Building " + this.name;
}

function ProvideDepotAction::_Do(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local entranceTile = context.rawget(this.entranceTileKey);
  local depotTile = RoadHelpers.BuildDepotNextToRoad(entranceTile);
  context.rawset(this.name + "_tile", depotTile);
}

function ProvideDepotAction::_Undo(context)
{
}
