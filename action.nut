
class Action
{
   constructor() { isDone = false; }

   // returns string: human-readable name of the plan
   function Name();

   // these functions return int
   function GetInitialCostEstimate();
   function GetMonthlyCostEstimate();
   function GetMonthlyIncomeEstimate();

   // return true if the action succeeded, false otherwise
   function Do(context);
   function Undo(context); // only to call after Do() finished successfully

   function _Do(context); // override in subclass
   function _Undo(context); // override in subclass

   local isDone = false;
}

function Action::Name()
{
   return "Unknown action";
}

function Action::GetInitialCostEstimate()
{
   return 0;
}

function Action::GetMonthlyCostEstimate()
{
   return 0;
}

function Action::GetMonthlyIncomeEstimate()
{
   return 0;
}

function Action::Do(context)
{
   if (isDone)
   {
      AILog.Error("Cannot do action " + Name() + ": action already done!");
      return false;
   }
   local result = _Do(context);
   if (result)
   {
      isDone = true;
   }
   return result;
}

function Action::Undo(context)
{
   if (!isDone)
   {
      AILog.Error("Cannon undo action " + Name() + ": action hasn't been done!");
      return false;
   }
   local result = _Undo(context);
   if (result)
   {
      isDone = false;
   }
   return result;
}

function Action::_Do(context)
{
   AILog.Error("The method " + getclass().getattributes().ClassName + "::_Do(context) is not defined!");
   return false;
}

function Action::_Undo(context)
{
   AILog.Error("The method " + getclass().getattributes().ClassName + "::_Undo(context) is not defined!");
   return false;
}
