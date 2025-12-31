require("Action.nut")
require("../BackgroundTask.nut")

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
  local timeoutDate = AIDate.GetCurrentDate() + 90; // 90 days timeout
  while(true)
  {
    // We wait until the station has cargo rating.
    // Thanks to that, the pickup station will not be considered to be included in the next plan.
    if (AIStation.HasCargoRating(stationId, this.cargoId))
    {
      break;
    }
    if (AIDate.GetCurrentDate() > timeoutDate)
    {
      // Eg. the industry might have closed, or the AI has just been restarted and the new AI chose a secondary industry.
      AILog.Warning("Timeout waiting for first truck at pickup station " + this.stationName + ".");
      throw "Timeout waiting for first truck at pickup station " + this.stationName + ".";
    }

    KrakenAI.BackgroundTask.Run();
    AILog.Info(Name(context));
    AIController.Sleep(50);
  }

}

function WaitForFirstTruckAtPickupAction::_Undo(context)
{
}
