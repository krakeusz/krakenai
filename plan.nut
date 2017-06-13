
class Plan
{
   constructor();

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

   local actions;
   local context;
}

Plan::constructor()
{
   actions = array(0);
   context = {};
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
   for (i, action in actions)
   {
      local succeeded = action.Do(context);
      if (!succeeded)
      {
         AILog.Warning("Action '" + action.Name() + "' failed!");

         // rollback previous actions
         for (local j = i - 1; j >= 0; j--)
         {
            AILog.Warning("Undoing '" + actions[j].Name() + "'");
            actions[j].Undo(context);
         }
         return false;
      }
      AILog.Info("Action '" + action.Name() + "' done.");
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

class RoadConnectionPlan extends Plan
{
   constructor(producerId, consumerId, cargoId);

   function Name();

   function _ChooseBestEngineId();

   local bestEngineId;
}

RoadConnectionPlan::constructor(producerId, consumerId, cargoId)
{
   ::Plan.constructor();

   context.producerId <- producerId;
   context.consumerId <- consumerId;
   context.cargoId <- cargoId;

   bestEngineId = _ChooseBestEngineId();

   local producerTileString = "producerStationTile";
   local consumerTileString = "consumerStationTile";
   _AddAction(ProvideStationAction(producerId, cargoId, producerTileString));
   _AddAction(ProvideStationAction(consumerId, cargoId, consumerTileString));
   _AddAction(FindAndBuildRoadAction(producerTileString, consumerTileString));
   _AddAction(ProvideDepotAction(producerTileString, "depot1"));
   _AddAction(ProvideDepotAction(consumerTileString, "depot2"));
   _AddAction(BuildTrucks(bestEngineId, cargoId, producerTileString, consumerTileString, "depot1"));
}

function RoadConnectionPlan::Name()
{
   return "Road connection between " + AIIndustry.GetName(context.producerId) +
          " and " + AIIndustry.GetName(context.consumerId) +
          " (" + AICargo.GetCargoLabel(context.cargoId) + ")";
}
