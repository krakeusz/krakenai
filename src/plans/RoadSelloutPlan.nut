require("Plan.nut");
require("../actions/SelloutRoadGroupAction.nut");

class RoadSelloutPlan extends Plan
{
  constructor(unprofitableGroups)
  {
    ::Plan.constructor();
    context.unprofitableGroups <- unprofitableGroups;
    this.name = "Selling out all " + unprofitableGroups.Count() + " unprofitable road routes";

    for (local groupId = unprofitableGroups.Begin(); !unprofitableGroups.IsEnd(); groupId = unprofitableGroups.Next())
    {
      _AddAction(SelloutRoadGroupAction(context, groupId));
    }
  }

  function Name()
  {
    return this.name;
  }

  name = "";
}