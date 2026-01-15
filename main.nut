import("util.superlib", "SuperLib", 40);

require("src/BackgroundTask.nut");
require("src/events/EventHandler.nut");
require("src/plans/PlanChooser.nut");
require("src/game/PersistentStorageWorker.nut");
require("src/game/PersistentStorage.nut");
require("src/names/PirateCompanyName.nut");

class KrakenAI extends AIController
{
  constructor()
  {
    PersistentStorage._proxy._worker = PersistentStorageWorker();
  }

  function SetCompanyInfo();
  function Start();

  static BackgroundTask = _KrakenAI_BackgroundTask();
}

function KrakenAI::SetCompanyInfo()
{
  PirateCo().SetCompanyName();
}

function KrakenAI::Start()
{
  SetCompanyInfo();
  SuperLib.Money.MaxLoan();
  local planChooser = PlanChooser();
  local eventHandler = EventHandler();
  while (true)
  {
    eventHandler.ProcessWaitingEvents();
    
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

function KrakenAI::Save()
{
  return PersistentStorage.Save();
}

function KrakenAI::Load(version, data)
{
  PersistentStorage.Load(version, data);
}


