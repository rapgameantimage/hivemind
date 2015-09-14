-- This file contains all barebones-registered events and has already set up the passed-in parameters for your use.
-- Do not remove the GameMode:_Function calls in these events as it will mess with the internal barebones systems.

-- An entity died
function GameMode:OnEntityKilled( keys )
  DebugPrint( '[BAREBONES] OnEntityKilled Called' )
  DebugPrintTable( keys )

  -- This internal handling is used to set up main barebones functions
  GameMode:_OnEntityKilled( keys )

  -- Don't do anything if we're in the midst of setting up a rematch
  local status = CustomNetTables:GetTableValue("gamestate", "status")
  if status ~= nil and status["1"] ~= nil and status["1"] == "rematch" then
    return
  end
  -- otherwise:
  
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  local killerEntity = nil

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  end

  local player = killedUnit:GetPlayerOwner()
  if player == nil then
    -- nothing to do here, really.
    return
  end

  local hero = player:GetAssignedHero()

  -- Treat this death differently depending on what kind of unit it is
  if killedUnit:IsHero() then
  	-- Increment enemy score
  	local enemy_team
  	if killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS then
  		enemy_team = DOTA_TEAM_BADGUYS
  	else
  		enemy_team = DOTA_TEAM_GOODGUYS
  	end
  	local score_table = CustomNetTables:GetTableValue("gamestate", "score")
  	local enemy_score = tonumber(score_table[tostring(enemy_team)])
 	enemy_score = enemy_score + 1
 	score_table[tostring(enemy_team)] = tostring(enemy_score)
  	CustomNetTables:SetTableValue("gamestate", "score", score_table)

    -- Kill the corresponding split units
    GameMode:KillCorrespondingSplitUnits(killedUnit)
    -- Complete this round
    GameMode:CompleteRound()

  -- ignore_split_unit_death is checking to see if this event got triggered by KillCorrespondingSplitUnits, basically.
  elseif killedUnit:GetUnitLabel() == "split_unit" and not CustomNetTables:GetTableValue("gamestate", "ignore_split_unit_death")[tostring(hero:GetEntityIndex())] then
    local units = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))
    -- Check if all split units are dead
    if units ~= nil then
      local found_living_split_unit = false
      for index,info in pairs(units) do
        if tonumber(index) == keys.entindex_killed then
          units[index] = nil
          CustomNetTables:SetTableValue("split_units", tostring(hero:GetEntityIndex()), units)
        elseif EntIndexToHScript(tonumber(index)) ~= nil then
          found_living_split_unit = true
        end
      end
      if not found_living_split_unit then
        -- Kill the corresponding hero
        hero:Kill(nil, killerEntity)
      end
    end
  end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
  DebugPrint("[BAREBONES] NPC Spawned")
  DebugPrintTable(keys)

  -- This internal handling is used to set up main barebones functions
  GameMode:_OnNPCSpawned(keys)

  local npc = EntIndexToHScript(keys.entindex)

  if npc:IsHero() then
    -- Create the corresponding split units for this hero
    CustomNetTables:SetTableValue("split_units", tostring(npc:GetEntityIndex()), {})
    -- See if the split units have been precached yet
    local split_name = SPLIT_UNIT_NAMES[npc:GetName()]
    if CustomNetTables:GetTableValue("precache_status", split_name) == nil then
      PrecacheUnitByNameAsync(split_name, function()
        print("Finished split precache for " .. npc:GetName())
        CustomNetTables:SetTableValue("precache_status", split_name, {"true"})
        GameMode:CreateSplitUnits(npc)
      end)
    else
      GameMode:CreateSplitUnits(npc)
    end

    -- Grant all abilities
    for i = 0,npc:GetAbilityCount()-1 do
      local abil = npc:GetAbilityByIndex(i)
      if abil ~= nil then
        abil:SetLevel(1)
      end
    end
    npc:SetAbilityPoints(0)
  end
end

-- currently only handles 2 players
-- event happens when a player clicks yes on the rematch popup (see main.js)
function GameMode:OnRematchYes(keys)
  PrintTable(keys)
  local tbl = CustomNetTables:GetTableValue("gamestate", "rematch")
  if tbl == nil then
    tbl = {}
  end
  tbl[tostring(keys.player)] = true
  PrintTable(tbl)

  if tbl[tostring(PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 1))] and tbl[tostring(PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, 1))] then
    -- A rematch was accepted by both players
    CustomNetTables:SetTableValue("gamestate", "status", {"rematch"})
    CustomNetTables:SetTableValue("gamestate", "rematch", {})
    CustomGameEventManager:Send_ServerToAllClients("rematch_accepted", {})
  else
    CustomNetTables:SetTableValue("gamestate", "rematch", tbl)
  end
end








-- unused events


-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
  DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
  DebugPrintTable(keys)

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid

end
-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
  DebugPrint("[BAREBONES] GameRules State Changed")
  DebugPrintTable(keys)

  -- This internal handling is used to set up main barebones functions
  GameMode:_OnGameRulesStateChange(keys)

  local newState = GameRules:State_Get()
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
  --DebugPrint("[BAREBONES] Entity Hurt")
  --DebugPrintTable(keys)

  --local damagebits = keys.damagebits -- This might always be 0 and therefore useless
  --local entCause = EntIndexToHScript(keys.entindex_attacker)
  --local entVictim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
  DebugPrint( '[BAREBONES] OnItemPickedUp' )
  DebugPrintTable(keys)

  local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
  DebugPrint( '[BAREBONES] OnPlayerReconnect' )
  DebugPrintTable(keys) 
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
  DebugPrint( '[BAREBONES] OnItemPurchased' )
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
  
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
  DebugPrint('[BAREBONES] AbilityUsed')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.PlayerID)
  local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
  DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
  DebugPrintTable(keys)

  local abilityname=  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
  DebugPrint('[BAREBONES] OnPlayerChangedName')
  DebugPrintTable(keys)

  local newName = keys.newname
  local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
  DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
  DebugPrint('[BAREBONES] OnAbilityChannelFinished')
  DebugPrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
  DebugPrint('[BAREBONES] OnPlayerLevelUp')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
  DebugPrint('[BAREBONES] OnLastHit')
  DebugPrintTable(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
  DebugPrint('[BAREBONES] OnTreeCut')
  DebugPrintTable(keys)

  local treeX = keys.tree_x
  local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
  DebugPrint('[BAREBONES] OnRuneActivated')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local rune = keys.rune

  --[[ Rune Can be one of the following types
  DOTA_RUNE_DOUBLEDAMAGE
  DOTA_RUNE_HASTE
  DOTA_RUNE_HAUNTED
  DOTA_RUNE_ILLUSION
  DOTA_RUNE_INVISIBILITY
  DOTA_RUNE_BOUNTY
  DOTA_RUNE_MYSTERY
  DOTA_RUNE_RAPIER
  DOTA_RUNE_REGENERATION
  DOTA_RUNE_SPOOKY
  DOTA_RUNE_TURBO
  ]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
  DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
  DebugPrint('[BAREBONES] OnPlayerPickHero')
  DebugPrintTable(keys)

  local heroClass = keys.hero
  local heroEntity = EntIndexToHScript(keys.heroindex)
  local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
  DebugPrint('[BAREBONES] OnTeamKillCredit')
  DebugPrintTable(keys)

  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
  local numKills = keys.herokills
  local killerTeamNumber = keys.teamnumber
end


-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function GameMode:PlayerConnect(keys)
  DebugPrint('[BAREBONES] PlayerConnect')
  DebugPrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
  DebugPrint('[BAREBONES] OnConnectFull')
  DebugPrintTable(keys)

  GameMode:_OnConnectFull(keys)
  
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)
  
  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
  DebugPrint('[BAREBONES] OnIllusionsCreated')
  DebugPrintTable(keys)

  local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
  DebugPrint('[BAREBONES] OnItemCombined')
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end
  local player = PlayerResource:GetPlayer(plyID)

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function GameMode:OnAbilityCastBegins(keys)
  DebugPrint('[BAREBONES] OnAbilityCastBegins')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
  DebugPrint('[BAREBONES] OnTowerKill')
  DebugPrintTable(keys)

  local gold = keys.gold
  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
  DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.player_id)
  local success = (keys.success == 1)
  local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
  DebugPrint('[BAREBONES] OnNPCGoalReached')
  DebugPrintTable(keys)

  local goalEntity = EntIndexToHScript(keys.goal_entindex)
  local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
  local npc = EntIndexToHScript(keys.npc_entindex)
end