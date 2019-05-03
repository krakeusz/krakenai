require("FifoQueue.nut")

// Searches the roads, starting from one tile, until a suitable tile is found.
// Returns the closest suitable tile found.
// Does NOT work with bridges/tunnels.
class BfsRoadPathfinder
{
  //! @param startTile The tile id that search will start from.
  //! @param finishTiles An AIList of tile ids. Search will end if one of these is encountered, or no tiles are within maxDistance.
  //! @param maxDistance The search will end if no tiles are within this distance. Distance is measured as path length.
  //! return null if nothing found, or tile id of closest finish tile.
  static function Find(startTile, finishTiles, maxDistance)
  {
    if (maxDistance < 0 || !AIMap.IsValidTile(startTile))
    {
      return null;
    }
    // Convert array to table, to ensure fast lookup.
    local finishTilesTable = {};
    for (local tile = finishTiles.Begin(); !finishTiles.IsEnd(); tile = finishTiles.Next())
    {
      finishTilesTable.rawset(tile, null);
    }
    // With 4 neighbours, there will be roughly maxDistance * 4 elements in the queue while searching a fully connected road graph.
    local q = FifoQueue(maxDistance * 5 + 1);
    local visited = {}; // tile -> distance from start
    q.Push(startTile);
    visited.rawset(startTile, 0);
    while (!q.IsEmpty())
    {
      local tile = q.Pop();
      local tileDistance = visited.rawget(tile);
      if (tileDistance > maxDistance)
      {
        return null; // Because we visit tiles in non-decreasing distance manner, if this distance is greater than max, then all future distances will be greater too.
      }
      if (finishTilesTable.rawin(tile))
      {
        return tile;
      }
      local neighbors = SuperLib.Tile.GetNeighbours4MainDir(tile);
      for (local neighborTile = neighbors.Begin(); !neighbors.IsEnd(); neighborTile = neighbors.Next())
      {
        if (AIMap.IsValidTile(neighborTile) && AIRoad.AreRoadTilesConnected(tile, neighborTile) && !visited.rawin(neighborTile))
        {
          visited.rawset(neighborTile, tileDistance + 1);
          q.Push(neighborTile);
        }
      }
    }
    return null;
  }


}