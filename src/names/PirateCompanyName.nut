/* Pirate-themed AI company naming code for OpenTTD.
   Names are pirate-based with adjectives, nouns, and company types.
   
   Inspired by a similar implementation in SimpleAI by 3iff licensed under GPLv2.
*/

class PirateCo
{
}

function PirateCo::SetCompanyName()
{
  // Adjectives - optional descriptors
  local co_pi_adjective = [
    "Black","Scarlet","Golden","Silver","Iron","Dread","Fearless","Bold","Cunning","Wicked",
    "Ruthless","Savage","Wild","Fierce","Rogue","Scurvy","Salty","Crimson","Dark","Bloody",
    "Cursed","Foul","Grim","Grisly","Merciless","Treacherous","Vicious","Villainous","Cutthroat"
  ];

  // Nouns - required core names
  local co_pi_noun = [
    "Blackbeard","Calico","Flint","Kidd","Morgan","Rackham","Roberts","Teach","Bellamy","Avery",
    "Drake","Hawkins","Hook","Sparrow","Barbossa","Bluebeard","Cutlass","Dagger","Scallywag","Swashbuckle",
    "Plunder","Corsair","Buccaneer","Privateer","Raider","Marauder","Kraken","Anchor","Galleon","Sloop",
    "Vessel","Brigantine","Frigate","Schooner","Whirlpool","Tempest","Storm","Wave","Tide","Current",
    "Skull","Crossbones","Compass","Lantern","Shark","Serpent","Dragon","Thunder","Lightning","Havoc",
    "Chaos","Phantom","Shadow","Specter","Wraith"
  ];

  // Company types - required suffixes
  local co_pi_type = [
    " Pirates"," Pirates"," Buccaneers"," Corsairs"," Raiders"," Privateers"," Crew"," Gang"," Fleet",
    " Armada"," Brotherhood"," Syndicate"," Company"," Company"," Incorporated"," Holdings"," Enterprises",
    " Ventures"," Trading Co"," Shipping"," Maritime"," Seafarers"," Salvage"," Plunder Inc"," Gold Rush",
    " Treasure Hunters"," Storm Chasers"," Wave Riders"," Wind Breakers"," Dockside"," Port Authority",
    " Nautical Co"," Sea Lines"," Ocean Routes"," Harbor Patrol"," Smugglers Ring"," Deck Hands",
    " Sailors Guild"," Captain's Quarters"," Cargo Masters",

    // These names won't go with certain formats so need to be skipped.
    // They must be the last 4 here, don't move them or add anything after them.
    " & Brothers"," & Co"," & Son"," & Sons"
  ];

  // Letters for initials
  local co_pi_letters = [
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
  ];

  // Generate a random number to select which type of name is produced.
  local rx = (AIBase.RandRange(11)) + 1;

  switch (rx) {
    // noun + type
    case 1:
    case 2:
      local i = AIBase.RandRange(co_pi_noun.len());
      local j = AIBase.RandRange(co_pi_type.len());
      while (!AICompany.SetName(co_pi_noun[i] + co_pi_type[j])) {
        i = AIBase.RandRange(co_pi_noun.len());
        j = AIBase.RandRange(co_pi_type.len());
      }
    break;

    // adjective + noun + type
    case 3:
    case 4:
      local h = AIBase.RandRange(co_pi_adjective.len());
      local i = AIBase.RandRange(co_pi_noun.len());
      local j = AIBase.RandRange(co_pi_type.len());
      while (!AICompany.SetName(co_pi_adjective[h] + " " + co_pi_noun[i] + co_pi_type[j])) {
        h = AIBase.RandRange(co_pi_adjective.len());
        i = AIBase.RandRange(co_pi_noun.len());
        j = AIBase.RandRange(co_pi_type.len());
      }
    break;

    // noun + noun + type
    case 5:
    case 6:
      local i = AIBase.RandRange(co_pi_noun.len());
      local k = AIBase.RandRange(co_pi_noun.len());
      local j = AIBase.RandRange(co_pi_type.len()-4);
      while (!AICompany.SetName(co_pi_noun[i] + " " + co_pi_noun[k] + co_pi_type[j])) {
        i = AIBase.RandRange(co_pi_noun.len());
        k = AIBase.RandRange(co_pi_noun.len());
        j = AIBase.RandRange(co_pi_type.len()-4);
      }
    break;

    // 3 initials + type
    case 7:
      local k1 = AIBase.RandRange(co_pi_letters.len());
      local k2 = AIBase.RandRange(co_pi_letters.len());
      local k3 = AIBase.RandRange(co_pi_letters.len());
      local j = AIBase.RandRange(co_pi_type.len()-4);
      while (!AICompany.SetName(co_pi_letters[k1] + co_pi_letters[k2] + co_pi_letters[k3] + co_pi_type[j])) {
        k1 = AIBase.RandRange(co_pi_letters.len());
        k2 = AIBase.RandRange(co_pi_letters.len());
        k3 = AIBase.RandRange(co_pi_letters.len());
        j = AIBase.RandRange(co_pi_type.len()-4);
      }
    break;

    // 2 initials + type
    case 8:
      local k1 = AIBase.RandRange(co_pi_letters.len());
      local k2 = AIBase.RandRange(co_pi_letters.len());
      local j = AIBase.RandRange(co_pi_type.len());
      while (!AICompany.SetName(co_pi_letters[k1] + co_pi_letters[k2] + co_pi_type[j])) {
        k1 = AIBase.RandRange(co_pi_letters.len());
        k2 = AIBase.RandRange(co_pi_letters.len());
        j = AIBase.RandRange(co_pi_type.len());
      }
    break;

    // initial + noun + type
    case 9:
    case 10:
      local i = AIBase.RandRange(co_pi_letters.len());
      local k = AIBase.RandRange(co_pi_noun.len());
      local j = AIBase.RandRange(co_pi_type.len());
      while (!AICompany.SetName(co_pi_letters[i] + ". " + co_pi_noun[k] + co_pi_type[j])) {
        i = AIBase.RandRange(co_pi_letters.len());
        k = AIBase.RandRange(co_pi_noun.len());
        j = AIBase.RandRange(co_pi_type.len());
      }
    break;

    // adjective + type
    case 11:
      local h = AIBase.RandRange(co_pi_adjective.len());
      local j = AIBase.RandRange(co_pi_type.len()-4);
      while (!AICompany.SetName(co_pi_adjective[h] + co_pi_type[j])) {
        h = AIBase.RandRange(co_pi_adjective.len());
        j = AIBase.RandRange(co_pi_type.len()-4);
      }
    break;

    default:
      local j = AIBase.RandRange(999) + 1;
      AICompany.SetName("Pirate Co " + j);
    break;
  }
}
