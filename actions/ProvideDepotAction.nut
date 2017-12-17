require("Action.nut")

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
  // TODO this will fail if the entrance tile is not a road, but a bridge
  local depotTile = SuperLib.Road.BuildDepotNextToRoad(entranceTile, 1, 20);
  if (null == depotTile) throw "Could not build a depot!";
  context.rawset(this.name + "_tile", depotTile);
}

function ProvideDepotAction::_Undo(context)
{
}
