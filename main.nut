import("util.superlib", "SuperLib", 40);

require("PlanChooser.nut");
require("BackgroundTaskWorker.nut");
require("BackgroundTask.nut");

class KrakenAI extends AIController
{
  function SetCompanyInfo();
  function Start();
  function HandleEvents();
}

function KrakenAI::SetCompanyInfo()
{
  if (!AICompany.SetName("KrakenAI")) {
    local i = 2;
    while (!AICompany.SetName("KrakenAI #" + i)) {
      i++;
    }
  }
}

function KrakenAI::Start()
{
  BackgroundTask._proxy._worker = BackgroundTaskWorker();
  SetCompanyInfo();
  SuperLib.Money.MaxLoan();
  local planChooser = PlanChooser();
  while (true)
  {
    HandleEvents();
    AILog.Info("KrakenAI: we are at tick " + this.GetTick());
    
    local plan = planChooser.NextPlan();
    if (plan != null)
    {
      plan.Realise();
    }

    AILog.Info("KrakenAI: we are at tick " + this.GetTick());
    AILog.Info("Remaining operations allowed this tick: " + this.GetOpsTillSuspend());
    this.Sleep(50);
  }
}

function KrakenAI::HandleEvents()
{
  while (AIEventController.IsEventWaiting())
  {
    local e = AIEventController.GetNextEvent();
    switch (e.GetEventType())
    {
      case AIEvent.ET_VEHICLE_CRASHED:
        local ec = AIEventVehicleCrashed.Convert(e);
        local vid  = ec.GetVehicleID();
        AILog.Info("We have a crashed vehicle (" + vid + ")");
        break;
    }
  }
}

