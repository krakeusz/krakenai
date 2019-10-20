require("Action.nut")
require("BackgroundTask.nut")

class WaitForFirstTruckAtPickupAction extends Action
{
  constructor(context, stationName, stationTileKey, cargoId)
  {
    ::Action.constructor();
    this.stationName = stationName;
    this.stationTileKey = stationTileKey;
    this.cargoId = cargoId;
  }

  function Name(context);
  function _Do(context);
  function _Undo(context);

  stationName = "";
  stationTileKey = "";
  cargoId = -1;
}

function WaitForFirstTruckAtPickupAction::Name(context)
{
  return "Waiting for first truck to arrive at pickup station " + this.stationName + "...";
}

function WaitForFirstTruckAtPickupAction::_Do(context)
{
  local stationId = AIStation.GetStationID(context.rawget(this.stationTileKey));
  while(true)
  {
    // We wait until the station has cargo rating.
    // Thanks to that, the pickup station will not be considered to be included in the next plan.
    if (AIStation.HasCargoRating(stationId, this.cargoId))
    {
      break;
    }
    KrakenAI.BackgroundTask.Run();
    AILog.Info(Name(context));
    AIController.Sleep(50);
  }

}

function WaitForFirstTruckAtPickupAction::_Undo(context)
{
}
