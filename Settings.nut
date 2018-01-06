class Settings
{
  static function GetSettings();

  static function CurrentAggressiveness();
}

function Settings::GetSettings()
{ 
  AddSetting({
      name = "Aggressiveness", 
      description = "Level of aggressiveness", 
      min_value = 0, 
      max_value = 2, 
      easy_value = 0, 
      medium_value = 1, 
      hard_value = 2, 
      custom_value = 1, 
      flags = AIInfo.CONFIG_INGAME
      });
  AddLabels("Aggressiveness", {
      _0 = "Dalai Lama (low)", 
      _1 = "Donald Trump (medium)",
      _2 = "Adolf Hitler (high)"
      });
}

function Settings::CurrentAggressiveness()
{
  return AIController.GetSetting("Aggressiveness");
}
