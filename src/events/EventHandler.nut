
class EventHandler
{
  function ProcessWaitingEvents();
  function _HandleEvent(event);
}

function EventHandler::ProcessWaitingEvents()
{
  while (AIEventController.IsEventWaiting())
  {
    local event = AIEventController.GetNextEvent();
    _HandleEvent(event);
  }
}

function EventHandler::_HandleEvent(event)
{
  switch (event.GetEventType())
  {
    case AIEvent.ET_VEHICLE_LOST:
      _HandleVehicleLostEvent(AIEventVehicleLost.Convert(event));
      break;
    default:
      break;
  }
}

function EventHandler::_HandleVehicleLostEvent(vehicleLostEvent)
{
  local vehicleId = vehicleLostEvent.GetVehicleID();
  AILog.Info("Vehicle lost event for vehicle ID " + vehicleId);
  if (!AIVehicle.IsValidVehicle(vehicleId))
  {
    AILog.Warning("Event Vehicle Lost: Vehicle ID " + vehicleId + " is not valid, perhaps not owned by us.");
    return;
  }
  if (AIVehicle.GetVehicleType(vehicleId) != AIVehicle.VT_ROAD)
  {
    AILog.Info("Event Vehicle Lost: Vehicle ID " + vehicleId + " is not a road vehicle, ignoring.");
    return;
  }
  TruckOrders.StopInDepot(vehicleId);
  AILog.Info("Event Vehicle Lost: Vehicle ID " + vehicleId + " was sent to a depot because it was lost.");
}