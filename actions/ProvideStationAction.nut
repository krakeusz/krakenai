require("Action.nut")
require("../RoadHelpers.nut")
require("../PersistentStorage.nut")

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
  function _FindStationRectNearIndustry();
  function _AddToAll(tileList, tile);
  function _BuildTerminusStation(stationTile, entranceTile, roadVehicleType);
  function _BuildRoroStation3x3(topLeftTile, roadVehicleType);
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
  local topLeftTile = _FindStationRectNearIndustry();
  context.rawset(this.stationTileKey + "entrance", topLeftTile);
  local roadVehicleType = AIRoad.GetRoadVehicleTypeForCargo(cargoId);
  _BuildRoroStation3x3(topLeftTile, roadVehicleType);
  context.rawset(this.stationTileKey, topLeftTile + AIMap.GetTileIndex(1, 1));
}

function ProvideStationAction::_Undo(context)
{
}

function ProvideStationAction::_OnError(context)
{
  local unusableIndustries = PersistentStorage.LoadUnusableIndustries();
  AILog.Info("Excluding " + AIIndustry.GetName(this.industryId) + " from possible industry list");
  unusableIndustries[this.industryId] <- true
  PersistentStorage.SaveUnusableIndustries(unusableIndustries);
}

function ProvideStationAction::_AddToAll(tileList, tile)
{
  local result = AITileList();
  for (local t = tileList.Begin(); !tileList.IsEnd(); t = tileList.Next())
  {
    t = t + tile;
    if (AIMap.IsValidTile(t))
    {
      result.AddTile(t);
    }
  }
  return result;
}

function ProvideStationAction::_FindStationRectNearIndustry()
{
  const STATION_RANGE = 3;
  const WIDTH = 3;
  const HEIGHT = 3;
  const CENTER_X = 1;
  const CENTER_Y = 1;
  local constr = (isProducer == 1 ? AITileList_IndustryProducing : AITileList_IndustryAccepting);
  local possibleTiles = constr(industryId, STATION_RANGE);
  local topLeftTiles = _AddToAll(possibleTiles, AIMap.GetTileIndex(-CENTER_X, -CENTER_Y));
  local excludedTopLeftTiles = AITileList();
  local excludeNotFlatTiles = function(topLeftTile, excludedTopLeftTiles) {
    local tiles = AITileList();
    tiles.AddRectangle(topLeftTile, topLeftTile + AIMap.GetTileIndex(WIDTH - 1, HEIGHT - 1));
    tiles.Valuate(SuperLib.Tile.IsBuildOnSlope_Flat);
    tiles.KeepValue(0);
    for (local excludedTile = tiles.Begin(); !tiles.IsEnd(); excludedTile = tiles.Next())
    {
      excludedTopLeftTiles.AddRectangle(excludedTile, excludedTile - AIMap.GetTileIndex(WIDTH - 1, HEIGHT - 1));
    }
  }
  while (true)
  {
    local bestTopLeftTile = AIMap.TILE_INVALID;
    local bestCost = 1000000;
    for (local tile = topLeftTiles.Begin(); !topLeftTiles.IsEnd(); tile = topLeftTiles.Next())
    {
      if (excludedTopLeftTiles.HasItem(tile)) continue;
      local costToFlatten = SuperLib.Tile.CostToFlattern(tile, WIDTH, HEIGHT);
      if (costToFlatten < 0) continue;
      if (costToFlatten < bestCost)
      {
        bestCost = costToFlatten;
        bestTopLeftTile = tile;
      }
    }
    if (bestTopLeftTile == AIMap.TILE_INVALID)
    {
      throw "No suitable tiles to build a road station near " + AIIndustry.GetName(industryId)
    }
    if (bestCost > 0)
    {
      RoadHelpers.WaitForFundsWithMargin(bestCost);
      if (!SuperLib.Tile.FlatternRect(bestTopLeftTile, WIDTH, HEIGHT))
      {
        AILog.Warning("Could not flatten area " + SuperLib.Tile.GetTileString(bestTopLeftTile) + " for station: " + AIError.GetLastErrorString());
        excludeNotFlatTiles(bestTopLeftTile, excludedTopLeftTiles);
        continue;
      }
      if (!SuperLib.Tile.IsTileRectBuildableAndFlat(bestTopLeftTile, WIDTH, HEIGHT))
      {
        AILog.Info("Area for station not flat although it was flattened!");
        excludeNotFlatTiles(bestTopLeftTile, excludedTopLeftTiles);
        continue;
      }
    }
    return bestTopLeftTile;
  }
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

function ProvideStationAction::_BuildTerminusStation(stationTile, entranceTile, roadVehicleType)
{
  local succeeded = AIRoad.BuildRoadStation(stationTile, entranceTile, roadVehicleType, AIStation.STATION_NEW);
  if (!succeeded)
  {
    throw "Building a station '" + this.stationName + "' at (" + SuperLib.Tile.GetTileString(stationTile) + ") failed: " + AIError.GetLastErrorString()
  }
  local stationId = AIStation.GetStationID(stationTile);
  _RenameStation(stationId);
}

function ProvideStationAction::_BuildRoroStation3x3(topLeftTile, roadVehicleType)
{
  // .---.
  // |   |
  // |-S-|
  // |   |
  // .-S-.
  local stationTile1 = topLeftTile + AIMap.GetTileIndex(1, 1);
  local stationTile2 = topLeftTile + AIMap.GetTileIndex(1, 2);
  RoadHelpers.BuildRoroStation(stationTile2, topLeftTile + AIMap.GetTileIndex(0, 2), roadVehicleType, AIStation.STATION_NEW);
  RoadHelpers.BuildRoroStation(stationTile1, topLeftTile + AIMap.GetTileIndex(0, 1), roadVehicleType, AIStation.STATION_JOIN_ADJACENT);
  // long segments
  RoadHelpers.BuildRoad(topLeftTile, topLeftTile + AIMap.GetTileIndex(2, 0));
  RoadHelpers.BuildRoad(topLeftTile, topLeftTile + AIMap.GetTileIndex(0, 2));
  RoadHelpers.BuildRoad(topLeftTile + AIMap.GetTileIndex(2, 0), topLeftTile + AIMap.GetTileIndex(2, 2));
  // short segments near stations
  RoadHelpers.BuildRoad(topLeftTile + AIMap.GetTileIndex(0, 1), stationTile1);
  RoadHelpers.BuildRoad(stationTile1, stationTile1 + AIMap.GetTileIndex(1, 0));
  RoadHelpers.BuildRoad(topLeftTile + AIMap.GetTileIndex(0, 2), stationTile2);
  RoadHelpers.BuildRoad(stationTile2, stationTile2 + AIMap.GetTileIndex(1, 0));
  local stationId = AIStation.GetStationID(stationTile1);
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

