require("Action.nut")
require("../game/PersistentStorage.nut")

class SelloutRoadGroupAction extends Action
{
  constructor(context, groupId)
  {
    ::Action.constructor();
    this.groupId = groupId;
  }

  groupId = -1;


  function Name(context)
  {
    return "Selling out road group " + AIGroup.GetName(this.groupId);
  }
  
  function _Do(context)
  {
    local vehicles = AIVehicleList_Group(this.groupId);
    local vehicleCount = vehicles.Count();
    local firstVehicle = true;
    for (local vehicle = vehicles.Begin(); !vehicles.IsEnd(); vehicle = vehicles.Next())
    {
      if (firstVehicle)
      {
        firstVehicle = false;
        local pickupTile = TruckOrders.GetPickupStationTile(vehicle);
        local dropTile = TruckOrders.GetDropStationTile(vehicle);
        ForbidNewConnections(pickupTile, dropTile);
      }
      AILog.Info("Sending vehicle " + AIVehicle.GetName(vehicle) + " # " + vehicle + " to depot.");
      TruckOrders.StopInDepot(vehicle);
    }
    AILog.Info("Sent " + vehicleCount + " vehicles from road group " + AIGroup.GetName(this.groupId) + " to a depot because the group is unprofitable.");
  }
  
  function _Undo(context)
  {

  }

  function ForbidNewConnections(pickupTile, dropTile)
  {
    local unprofitableConnections = PersistentStorage.LoadUnprofitableConnections();
    unprofitableConnections.append({pickupTileId = pickupTile, dropTileId = dropTile}); // change this to tiles
    PersistentStorage.SaveUnprofitableConnections(unprofitableConnections);
    AILog.Warning("Forbidden new connections between " + pickupTile + " and " + dropTile);
  }
}