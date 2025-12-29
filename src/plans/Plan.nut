require("../actions/Action.nut");

class Plan
{
  constructor()
  {
    actions = array(0);
    context = {};
  }

  // returns string: human-readable name of the plan
  function Name();

  // these functions return int
  function GetInitialCostEstimate();
  function GetMonthlyCostEstimate();
  function GetMonthlyIncomeEstimate();

  // return true/false
  function ArePrerequisitesSatisfied();

  // return true if the realisation succeeded, false otherwise
  function Realise();

  function _AddAction(action);
  function _SetInitialContext(context);

  actions = null;
  context = null;
}

function Plan::Name()
{
  return "Unknown plan";
}

function Plan::GetInitialCostEstimate()
{
  return 0;
}

function Plan::GetMonthlyCostEstimate()
{
  return 0;
}

function Plan::GetMonthlyIncomeEstimate()
{
  return 0;
}

function Plan::Realise()
{
  foreach (i, action in actions)
  {
    local succeeded = action.Do(context);
    KrakenAI.BackgroundTask.Run();
    if (!succeeded)
    {
      AILog.Warning("Action '" + action.Name(context) + "' failed!");

      // rollback previous actions
      for (local j = i - 1; j >= 0; j--)
      {
        AILog.Warning("Undoing '" + actions[j].Name(context) + "'");
        actions[j].Undo(context);
      }
      return false;
    }
    AILog.Info("Action '" + action.Name(context) + "' done.");
  }
  AILog.Info("Plan '" + Name() + "' realised.");
  return true;
}

function Plan::_AddAction(action)
{
  actions.append(action);
}

function Plan::_SetInitialContext(c)
{
  context = c;
}

