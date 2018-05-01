class Action
{
  constructor(){}

  // returns string: human-readable name of the plan
  function Name(context);

  // these functions return int
  function GetInitialCostEstimate();
  function GetMonthlyCostEstimate();
  function GetMonthlyIncomeEstimate();

  // return true if the action succeeded, false otherwise
  function Do(context);
  function Undo(context); // only to call after Do() finished successfully

  function _Do(context); // override in subclass
  function _Undo(context); // override in subclass
  function _OnError(context); // override if you want to

  isDone = false;
}

function Action::Name(context)
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
  try
  {
    if (this.isDone)
    {
      throw "Cannot do action " + Name(context) + ": action already done!"
    }
    _Do(context);
    this.isDone = true;
    return true;
  }
  catch (exceptionString)
  {
    AILog.Error(exceptionString);
    if (!this.isDone)
    {
      _OnError(context);
    }
    return false;
  }
}

function Action::Undo(context)
{
  try
  {
    if (!isDone)
    {
      throw "Cannot undo action " + Name() + ": action hasn't been done!"
    }
    _Undo(context);
    isDone = false;
    return true;
  }
  catch (exceptionString)
  {
    AILog.Error(exceptionString);
    return false;
  }
}

function Action::_Do(context)
{
  throw "The method " + getclass().getattributes().ClassName + "::_Do(context) is not defined!"
}

function Action::_Undo(context)
{
  throw "The method " + getclass().getattributes().ClassName + "::_Undo(context) is not defined!"
}

function Action::_OnError(context)
{
}

