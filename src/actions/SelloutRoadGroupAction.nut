require("Action.nut")
require("../road_helpers/RoadHelpers.nut")

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
        RoadHelpers.ForbidNewConnections(pickupTile, dropTile);
      }
      AILog.Info("Sending vehicle " + AIVehicle.GetName(vehicle) + " # " + vehicle + " to depot.");
      TruckOrders.StopInDepot(vehicle);
    }
    AILog.Info("Sent " + vehicleCount + " vehicles from road group " + AIGroup.GetName(this.groupId) + " to a depot because the group is unprofitable.");
  }
  
  function _Undo(context)
  {

  }

  
}