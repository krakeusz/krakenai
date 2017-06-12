
class KrakenAIInfo extends AIInfo {
  function GetAuthor()      { return "Mateusz 'krakeusz' Krakowiak"; }
  function GetName()        { return "KrakenAI"; }
  function GetDescription() { return "An AI that tries to use trains extensively. Hail OpenTTDCoop!"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2017-06-02"; }
  function CreateInstance() { return "KrakenAI"; }
  function GetShortName()   { return "KRAI"; }
  function GetAPIVersion()  { return "1.3"; }
  // TODO GetURL()
}

RegisterAI(KrakenAIInfo());
