class TruckOrders
{
  static function SetDefaultTruckOrders(vehicleId, station1Tile, station2Tile, depot1Tile, depot2Tile);
  static function StopInDepot(vehicleId);
  static function IsStoppingAtDepot(vehicleId);
  static function GetPickupStationTile(vehicleId);
  static function GetDropStationTile(vehicleId);

  static PICKUP_ORDER = 0;
  static DROP_ORDER = 1;
  static STOP_IN_DEPOT_ORDER = 5;
}

function TruckOrders::SetDefaultTruckOrders(vehicleId, station1Tile, station2Tile, depot1Tile, depot2Tile, isRoundTrip)
{
  AIOrder.AppendOrder(vehicleId, station1Tile, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
  local unloadFlags = (isRoundTrip ? AIOrder.OF_UNLOAD : AIOrder.OF_UNLOAD | AIOrder.OF_NO_LOAD);
  AIOrder.AppendOrder(vehicleId, station2Tile, AIOrder.OF_NON_STOP_INTERMEDIATE | unloadFlags);
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
  AIVehicle.SendVehicleToDepot(vehicleId); // in case the original depot from the order is not reachable
  AIOrder.SkipToOrder(vehicleId, TruckOrders.STOP_IN_DEPOT_ORDER);
}

function TruckOrders::IsStoppingAtDepot(vehicleId)
{
  local currentOrderIndex = AIOrder.ResolveOrderPosition(vehicleId, AIOrder.ORDER_CURRENT);
  return currentOrderIndex == TruckOrders.STOP_IN_DEPOT_ORDER;
}

function TruckOrders::GetPickupStationTile(vehicleId)
{
  return AIOrder.GetOrderDestination(vehicleId, TruckOrders.PICKUP_ORDER);
}

function TruckOrders::GetDropStationTile(vehicleId)
{
  return AIOrder.GetOrderDestination(vehicleId, TruckOrders.DROP_ORDER);
}