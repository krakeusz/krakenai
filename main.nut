import("util.superlib", "SuperLib", 40);

require("src/BackgroundTask.nut");
require("src/plans/PlanChooser.nut");
require("src/game/PersistentStorageWorker.nut");
require("src/game/PersistentStorage.nut");

class KrakenAI extends AIController
{
  constructor()
  {
    PersistentStorage._proxy._worker = PersistentStorageWorker();
  }

  function SetCompanyInfo();
  function Start();
  function HandleEvents();

  static BackgroundTask = _KrakenAI_BackgroundTask();
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
  SetCompanyInfo();
  SuperLib.Money.MaxLoan();
  local planChooser = PlanChooser();
  while (true)
  {
    HandleEvents();
    
    local plan = planChooser.NextPlan();
    if (plan != null)
    {
      plan.Realise();
    }
    else
    {
      BackgroundTask.Run();
    }

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

function KrakenAI::Save()
{
  return PersistentStorage.Save();
}

function KrakenAI::Load(version, data)
{
  PersistentStorage.Load(version, data);
}


