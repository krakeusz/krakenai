require("Action.nut")
require("../RoadHelpers.nut")

import("util.superlib", "SuperLib", 40);

// Builds a station, or reuses one.
class ProvideStationAction extends Action
{
  constructor(context, industryId, cargoId, stationTileKey, isProducer, stationName)
  {
    ::Action.constructor();
    this.industryId = industryId;
    this.cargoId = cargoId;
    this.stationTileKey = stationTileKey;
    this.isProducer = isProducer;
    this.stationName = stationName;
  }

  function Name(context);

  // sets context."value" with the station coordinates, depending on value of stationTileKey.
  // sets context."value"entrance with entrance tile coordinates
  function _Do(context);
  function _Undo(context);

  function _FindStationTileNearIndustry();
  function _BuildStation(stationTile, entranceTile, roadVehicleType);
  function _RenameStation(stationId);

  industryId = -1;
  cargoId = -1;
  stationTileKey = "";
  isProducer = 0;
  stationName = "";
}

function ProvideStationAction::Name(context)
{
  return "Providing road station " + this.stationName;
}

function ProvideStationAction::_Do(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local stationTile = _FindStationTileNearIndustry();
  local entranceTile = stationTile + AIMap.GetTileIndex(0, 1);
  context.rawset(this.stationTileKey + "entrance", entranceTile);
  local roadVehicleType = AIRoad.GetRoadVehicleTypeForCargo(cargoId);
  _BuildStation(stationTile, entranceTile, roadVehicleType)
  RoadHelpers.BuildRoad(stationTile, entranceTile);
  context.rawset(this.stationTileKey, stationTile)
}

function ProvideStationAction::_Undo(context)
{
}

function ProvideStationAction::_FindStationTileNearIndustry()
{
  const KRAI_STATION_RADIUS = 3;
  local constr = (isProducer == 1 ? AITileList_IndustryProducing : AITileList_IndustryAccepting);
  local stationTiles = constr(industryId, KRAI_STATION_RADIUS);
  stationTiles.Valuate(AITile.IsBuildable);
  stationTiles.KeepValue(1);
  stationTiles.Valuate(SuperLib.Tile.IsBuildOnSlope_FlatForTerminusInDirection, SuperLib.Direction.DIR_SE);
  stationTiles.KeepValue(1);
  if (stationTiles.IsEmpty())
  {
    throw "No suitable tiles to build a road station near " + AIIndustry.GetName(industryId)
  }
  return stationTiles.Begin();
}

function ProvideStationAction::_BuildStation(stationTile, entranceTile, roadVehicleType)
{
  local succeeded = AIRoad.BuildRoadStation(stationTile, entranceTile, roadVehicleType, AIStation.STATION_NEW);
  if (!succeeded)
  {
    throw "Building a station '" + this.stationName + "' at (" + SuperLib.Tile.GetTileString(stationTile) + ") failed: " + AIError.GetLastErrorString()
  }
  local stationId = AIStation.GetStationID(stationTile);
  _RenameStation(stationId);
}

function ProvideStationAction::_RenameStation(stationId)
{
  local i = 1;
  local newStationName = this.stationName;
  AILog.Info("Trying to rename station to " + newStationName);
  local success = false;
  do
  {
    success = AIBaseStation.SetName(stationId, newStationName);
    if (!success && AIError.GetLastError() != AIError.ERR_NAME_IS_NOT_UNIQUE)
    {
      AILog.Warning("Could not rename station: " + AIError.GetLastErrorString());
      break;
    }
    i++;
    newStationName = this.stationName + " " + i;
  } while (!success);
}

