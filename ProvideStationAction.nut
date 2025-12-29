require("Action.nut")
require("RoadHelpers.nut")
require("PersistentStorage.nut")
require("StationName.nut")

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

  function _TryReusingStation(context);
  function _BuildNewStation(context);
  function _FindStationTileNearIndustry();
  function _FindStationRectNearIndustry();
  function _AddToAll(tileList, tile);
  function _BuildTerminusStation(stationTile, entranceTile, roadVehicleType);
  function _BuildRoroStation3x3(topLeftTile, roadVehicleType);

  static function _IsCargoAcceptedByIndustry(station_id, cargo_id, industry_id);
  static function _IsDropStation(station_id);


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
  if (!_TryReusingStation(context))
  {
    _BuildNewStation(context);
  }
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

// Copied from SuperLib, as calling this function would result in strange error with wrong number of parameters.
/*static*/ function ProvideStationAction::_IsCargoAcceptedByIndustry(station_id, cargo_id, industry_id)
{
	local max_coverage_radius = SuperLib.Station.GetMaxCoverageRadius(station_id);

	local industry_coverage_tiles = AITileList_IndustryAccepting(industry_id, max_coverage_radius);
	industry_coverage_tiles.Valuate(SuperLib.Station.IsStation, station_id);
	industry_coverage_tiles.KeepValue(1);

	return !industry_coverage_tiles.IsEmpty() && SuperLib.Station.IsCargoAccepted(station_id, cargo_id);
}

function ProvideStationAction::_TryReusingStation(context)
{
  if (isProducer) return false;

  local dropStations = AIStationList(AIStation.STATION_TRUCK_STOP);
  dropStations.Valuate(ProvideStationAction._IsDropStation);
  dropStations.KeepValue(1);
  local isCargoAccepted = function(stationId, cargoId, industryId)
  {
    return ProvideStationAction._IsCargoAcceptedByIndustry(stationId, cargoId, industryId) ? 1 : 0;
  };
  dropStations.Valuate(ProvideStationAction._IsCargoAcceptedByIndustry, this.cargoId, this.industryId);
  dropStations.KeepValue(1);
  dropStations.Valuate(RoadHelpers.IncomingTrucksCount);
  dropStations.KeepBelowValue(6);
  dropStations.Sort(AIList.SORT_BY_VALUE, true);
  if (dropStations.IsEmpty()) return false;

  local station = dropStations.Begin();
  local stationTile = AIStation.GetLocation(station);
  context.rawset(this.stationTileKey, stationTile);
  context.rawset(this.stationTileKey + "entrance", stationTile + AIMap.GetTileIndex(-1, -1));
  return true;
}

function ProvideStationAction::_BuildNewStation(context)
{
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local topLeftTile = _FindStationRectNearIndustry();
  context.rawset(this.stationTileKey + "entrance", topLeftTile);
  local roadVehicleType = AIRoad.GetRoadVehicleTypeForCargo(cargoId);
  _BuildRoroStation3x3(topLeftTile, roadVehicleType);
  context.rawset(this.stationTileKey, topLeftTile + AIMap.GetTileIndex(1, 1));
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
        // TODO: ERR_NONE is not a good error
        local errorReason = AIError.GetLastErrorString();
        excludeNotFlatTiles(bestTopLeftTile, excludedTopLeftTiles);
        if (AITile.GetCornerHeight(bestTopLeftTile, AITile.CORNER_N) == 0)
        {
          // If the N corner is at sea level, then it's still possible that this tile is considered flat by SuperLib.
          // In that scenario, we would not exclude that tile and fall into infinite loop.
          excludedTopLeftTiles.AddTile(bestTopLeftTile);
          errorReason = "Cannot raise top rectangle tile above sea level";
        }
        AILog.Warning("Could not flatten area " + SuperLib.Tile.GetTileString(bestTopLeftTile) + " for station: " + errorReason);
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
}

function ProvideStationAction::_IsDropStation(station_id)
{
  // Check if station has any cargo rating.
  local cargos = AICargoList();
  local hasCargoRating = function(cargoId, stationId)
  {
    return AIStation.HasCargoRating(stationId, cargoId) ? 1 : 0;
  };
  cargos.Valuate(hasCargoRating, station_id);
  cargos.KeepValue(1);
  return cargos.IsEmpty() ? 1 : 0;
}

