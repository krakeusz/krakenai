require("Settings.nut")

class KrakenAIInfo extends AIInfo {
  function GetAuthor()      { return "Mateusz 'krakeusz' Krakowiak"; }
  function GetName()        { return "KrakenAI"; }
  function GetDescription() { return "An AI that tries to be smart using trucks."; }
  function GetVersion()     { return 2; }
  function GetDate()        { return "2019-10-20"; }
  function CreateInstance() { return "KrakenAI"; }
  function GetShortName()   { return "KRAI"; }
  function GetAPIVersion()  { return "1.3"; }
  function GetURL()         { return "https://github.com/krakeusz/krakenai"; }
  function GetSettings()    { return Settings.GetSettings(); }
}

RegisterAI(KrakenAIInfo());
