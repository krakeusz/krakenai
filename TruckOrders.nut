class TruckOrders
{
  static function SetDefaultTruckOrders(vehicleId, station1Tile, station2Tile, depot1Tile, depot2Tile);
  static function StopInDepot(vehicleId);

  static PICKUP_ORDER = 0;
  static STOP_IN_DEPOT_ORDER = 5;
}

function TruckOrders::SetDefaultTruckOrders(vehicleId, station1Tile, station2Tile, depot1Tile, depot2Tile)
{
  AIOrder.AppendOrder(vehicleId, station1Tile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
  AIOrder.AppendOrder(vehicleId, station2Tile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_UNLOAD | AIOrder.OF_NO_LOAD);
  AIOrder.AppendOrder(vehicleId, depot2Tile, AIOrder.OF_NONE | AIOrder.OF_NON_STOP_INTERMEDIATE);
  AIOrder.AppendOrder(vehicleId, depot1Tile, AIOrder.OF_NONE | AIOrder.OF_NON_STOP_INTERMEDIATE);
  local conditionalOrderPosition = AIOrder.GetOrderCount(vehicleId);
  AIOrder.AppendConditionalOrder(vehicleId, TruckOrders.PICKUP_ORDER);
  AIOrder.SetOrderCondition(vehicleId, conditionalOrderPosition, AIOrder.OC_UNCONDITIONALLY);
  local stopInDepotOrderPosition = AIOrder.GetOrderCount(vehicleId);
  assert (stopInDepotOrderPosition == TruckOrders.STOP_IN_DEPOT_ORDER);
  AIOrder.AppendOrder(vehicleId, depot1Tile, AIOrder.OF_STOP_IN_DEPOT | AIOrder.OF_NON_STOP_INTERMEDIATE);
  AIVehicle.StartStopVehicle(vehicleId);
}

function TruckOrders::StopInDepot(vehicleId)
{
  AIOrder.SkipToOrder(vehicleId, TruckOrders.STOP_IN_DEPOT_ORDER);
}
