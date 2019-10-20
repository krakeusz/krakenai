require("Action.nut")

class TemplateAction extends Action
{
  constructor()
  {
    ::Action.constructor();
  }

  function Name(context);
  function _Do(context);
  function _Undo(context);
}

function TemplateAction::Name(context)
{
  return "";
}

function TemplateAction::_Do(context)
{
}

function TemplateAction::_Undo(context)
{
}
