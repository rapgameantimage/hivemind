BAREBONES_DEBUG_SPEW = false

if GameMode == nil then
    DebugPrint( '[BAREBONES] creating barebones game mode' )
    _G.GameMode = class({})
end

-- Barebones stuff
require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/animations')
require('internal/gamemode')
require('internal/events')
require('settings')
require('events')

-- External libraries
require("libraries/vector_target")
require("statcollection/init")

-- My generalized stuff
require('helper_functions')

-- Hivemind-specific stuff
require('split_unit_definitions')
require('split_logic')
require('arena')

HIVEMIND_VERSION = "0.03"

MAX_RADIUS_FOR_UNIFY = 800
SPLIT_DELAY = 0.5
UNIFY_DELAY = 0.5

KILLS_TO_WIN = 5
POST_ROUND_DELAY = 5 -- Also set this in main.js

hover_boots_movement = {}

-- Variables for stat collection
statCollection:setFlags({version = HIVEMIND_VERSION, kills_to_win = KILLS_TO_WIN})
match_count = 0   -- This will be incremented to 1 before anyone plays because Rematch() is always called
round_times = {}
hero_time = {}
split_time = {}
last_form_change = {}

function GameMode:PostLoadPrecache()
  DebugPrint("[BAREBONES] Performing Post-Load precache")    
end

function GameMode:OnFirstPlayerLoaded()
  DebugPrint("[BAREBONES] First Player has loaded")
end

function GameMode:OnAllPlayersLoaded()
  DebugPrint("[BAREBONES] All Players have loaded into the game")
end

function GameMode:OnHeroInGame(hero)
  DebugPrint("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())
end

function GameMode:OnGameInProgress()
  -- ...
end

function GameMode:InitGameMode()
  GameMode = self
  DebugPrint('[BAREBONES] Starting to load Barebones gamemode...')

  GameMode:_InitGameMode()

  LinkLuaModifier("modifier_hidden", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_splitting", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_ok_to_complete_transformation", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_postmortem_damage_source", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_waiting_for_new_round", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_nonexistent", "modifiers", LUA_MODIFIER_MOTION_NONE)

  Convars:RegisterCommand( "test", Dynamic_Wrap(GameMode, 'test'), "For testing things", FCVAR_CHEAT )
  Convars:RegisterCommand( "completeround", Dynamic_Wrap(GameMode, 'CompleteRound'), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "rematch", Dynamic_Wrap(GameMode, 'Rematch'), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "update_abilities", Dynamic_Wrap(GameMode, "UpdateAbilities"), "For testing abilities", FCVAR_CHEAT )
  Convars:RegisterCommand( "cleanup_particles", Dynamic_Wrap(GameMode, "CleanupParticles"), "Destroy lots of particles", FCVAR_CHEAT )
  Convars:RegisterCommand( "arena_shrink", Dynamic_Wrap(Arena, "Shrink"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "set_kills_to_win", Dynamic_Wrap(GameMode, "SetKillsToWin"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "endgame", Dynamic_Wrap(GameMode, "ConsoleForceEndgame"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "changehero", Dynamic_Wrap(GameMode, "ConsolePickHero"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "bot_rematch_yes", Dynamic_Wrap(GameMode, "BotRematchYes"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "bot_pick_hero", Dynamic_Wrap(GameMode, "BotPickHero"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "bot_rematch_no", Dynamic_Wrap(GameMode, "BotRematchNo"), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "bot_changehero", Dynamic_Wrap(GameMode, "BotChangeHero"), "", FCVAR_CHEAT )

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')

  CustomNetTables:SetTableValue("gamestate", "round", {0})
  CustomNetTables:SetTableValue("gamestate", "score", {[tostring(DOTA_TEAM_GOODGUYS)] = "0", [tostring(DOTA_TEAM_BADGUYS)] = "0"})
  CustomNetTables:SetTableValue("gamestate", "ignore_split_unit_death", {})

  CustomGameEventManager:RegisterListener("rematch_yes", Dynamic_Wrap(GameMode, 'OnRematchYes'))
  CustomGameEventManager:RegisterListener("rematch_no", Dynamic_Wrap(GameMode, 'OnRematchNo'))
  CustomGameEventManager:RegisterListener("move_camera", Dynamic_Wrap(GameMode, 'MoveCamera'))
  CustomGameEventManager:RegisterListener("new_hero_picked", Dynamic_Wrap(GameMode, 'OnPickNewHero'))
  CustomGameEventManager:RegisterListener("player_needs_fake_hero", Dynamic_Wrap(GameMode, 'CreateFakeHero'))

  FilterManager:Init()

  VectorTarget:Init({noOrderFilter = true})
  FilterManager:AddFilter("order", function(ctx, params)
      return VectorTarget:OrderFilter(params)
    end,
  {})
end

if GameRules:GetGameModeEntity() then
  FilterManager:AddFilter("order", function(ctx, params)
      return VectorTarget:OrderFilter(params)
    end,
  {})
end

-- Reloads scripts and replaces the hero with itself in order. Intended for testing ability scripts.
function GameMode:UpdateAbilities()
  SendToConsole("script_reload")
  SendToConsole("cl_script_reload")
  for k,hero in pairs(HeroList:GetAllHeroes()) do
    GameMode:KillCorrespondingSplitUnits(hero)
    PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), hero:GetClassname(), PlayerResource:GetGold(hero:GetPlayerID()), hero:GetCurrentXP())
    hero:Destroy()
  end
end

function GameMode:test(x)
  PrintTable(BuildRoundWinnerArray())
end

function GameMode:SetKillsToWin(kills)
  if tonumber(kills) then
    KILLS_TO_WIN = tonumber(kills)
    statCollection:setFlags({kills_to_win = KILLS_TO_WIN})
  end
end

function GameMode:CleanupParticles()
  for i = 1,1000 do
    ParticleManager:DestroyParticle(i, true)
  end
end

function GameMode:GetCurrentRound()
  return next(CustomNetTables:GetTableValue("gamestate", "round"))
end

function GameMode:GetRound()
  return tonumber(CustomNetTables:GetTableValue("gamestate", "round")["1"])
end

-- This function gets called when:
-- (a) the game starts for the first time (from GameMode:OnGameInProgress() in gamemode.lua)
-- (b) a hero dies (from events.lua)
-- (c) a rematch begins (from GameMode:Rematch())
-- (d) the "completeround" console command is entered
-- In (a) and (c) the name is really a bit of a misnomer, but whatever.
function GameMode:CompleteRound()
  local currentround = GameMode:GetRound()

  -- Note the length of the round
  if currentround then
    if currentround > 0 then
      if round_times[currentround] then
        round_times[currentround].end_time = GameRules:GetGameTime()
        round_times[currentround].length = round_times[currentround].end_time - round_times[currentround].start_time
      end
    end
  end

  -- Count this as the end of hero/split form for surviving units
  for k,hero in pairs(HeroList:GetAllHeroes()) do
    GameMode:EndFormCounter(hero)
  end

  -- See if someone has won
  if GameMode:GetScoreForTeam(DOTA_TEAM_GOODGUYS) >= KILLS_TO_WIN then
    GameMode:DeclareWinner(DOTA_TEAM_GOODGUYS)
  elseif GameMode:GetScoreForTeam(DOTA_TEAM_BADGUYS) >= KILLS_TO_WIN then
    GameMode:DeclareWinner(DOTA_TEAM_BADGUYS)
  else
  	-- See whether we are starting a new match, or just a new round in an ongoing match
  	-- Either way, triggers the "Round X in 5..." text in main.js, and an update to the top bar
    if currentround == nil then
      CustomGameEventManager:Send_ServerToAllClients("match_started", {})
    else
      CustomGameEventManager:Send_ServerToAllClients("round_completed", {round = currentround})
    end
    CustomNetTables:SetTableValue("gamestate", "status", { "between_rounds" })
    -- Starts the new round after the countdown (which is handled by Panorama in main.js)
    Timers:CreateTimer(POST_ROUND_DELAY, function()
      GameMode:NewRound()
    end)
  end
end

-- This probably doesn't NEED to be a separate function but I feel like it's cleaner this way.
-- It's only called from GameMode:CompleteRound(), unless I'm forgetting something.
-- Does the dirty work of actually setting up a new round for our wonderful players.
function GameMode:NewRound()
  -- Gamestate tracking
  CustomNetTables:SetTableValue("gamestate", "status", { "gameplay" })
  local currentround = CustomNetTables:GetTableValue("gamestate", "round")
  local newroundnum = tonumber(currentround["1"]) + 1
  print("Starting round " .. newroundnum)
  if currentround == nil then
    CustomNetTables:SetTableValue("gamestate", "round", { 1 })
  else
    CustomNetTables:SetTableValue("gamestate", "round", { newroundnum })
  end

  -- Zero out the times used for tracking round length and time spent in each form
  round_times[newroundnum] = {start_time = GameRules:GetGameTime()}
  local timestamp = GameRules:GetGameTime()
  for k,player in pairs(GetPlayersOnTeams({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS})) do
    last_form_change[player] = timestamp
  end

  -- Cleanup
  GameMode:ClearArena()
  GridNav:RegrowAllTrees()
  GameRules:SetTimeOfDay(0.25)
  Arena:Reset(true)

  -- Respawn heroes
  for k,hero in pairs(HeroList:GetAllHeroes()) do
    hero:Interrupt()
    -- We have to have a momentary delay here, because otherwise channeling doesn't get interrupted properly for some reason. I dunno.
    Timers:CreateTimer(0.03, function()
      -- Manually cancel ongoing transformations and return to hero form
      if hero:HasModifier("modifier_ok_to_complete_transformation") then
        hero:RemoveModifierByName("modifier_ok_to_complete_transformation")
      end
      if hero:HasModifier("modifier_hidden") then
        hero:RemoveModifierByName("modifier_hidden")
      end
      if hero:HasModifier("modifier_spread_count") then
        hero:RemoveModifierByName("modifier_spread_count")
      end
      GameMode:KillCorrespondingSplitUnits(hero)

      -- Actually recreate the hero
      hero:Purge(true, true, false, true, true)
      for i = 0,hero:GetAbilityCount() - 1 do
        local ability = hero:GetAbilityByIndex(i)
        if ability ~= nil then ability:EndCooldown() end
      end
      hero:RespawnHero(false, false, false) -- wtf do these args do???

      local player = hero:GetPlayerOwner()
      last_form_change[player] = {form = "hero", time = GameRules:GetGameTime()}
    end)
  end

  -- Triggers the "ROUND X" text in main.js
  Timers:CreateTimer(0.03, function()
    CustomGameEventManager:Send_ServerToAllClients("round_started", {round = newroundnum})
  end)
end

function GameMode:DeclareWinner(team)
  CustomGameEventManager:Send_ServerToAllClients("match_completed", {winning_team = team})
  CustomNetTables:SetTableValue("gamestate", "winning_team", { tostring(team) })
  CustomNetTables:SetTableValue("gamestate", "status", { "finished" })
  customSchema:submitRound()
end

function GameMode:GetScoreForTeam(team)
  return tonumber(CustomNetTables:GetTableValue("gamestate", "score")[tostring(team)])
end

-- Used to trigger camera movement from panorama.
function GameMode:MoveCamera(event)
  PlayerResource:SetCameraTarget(event.PlayerID, EntIndexToHScript(event.target))
  Timers:CreateTimer(function()
    PlayerResource:SetCameraTarget(event.PlayerID, nil)
  end)
end

-- Clean up thinkers and miscellaneous other things (eggs, firewalls, nightmare orbs...) when creating a new round
-- Checks for the unit label "destroy_on_new_round" on npc_dota_creature types to see whether it should clear them. Add that label to make a unit be cleaned up by this function.
function GameMode:ClearArena()
  local DESTROY_ALWAYS = 1
  local DESTROY_CHECK_LABEL = 2
  local classes_to_check = {
    npc_dota_thinker = DESTROY_ALWAYS,
    npc_dota_creature = DESTROY_CHECK_LABEL,
  }
  for class,v in pairs(classes_to_check) do
    local ents = Entities:FindAllByClassname(class)
    if ents ~= nil then
      for k,ent in pairs(ents) do
        if classes_to_check[class] == DESTROY_ALWAYS or ent:GetUnitLabel() == "destroy_on_new_round" then
          ent:Attribute_SetIntValue("die_quietly", 1)     -- Can be referenced in abilities as necessary to provide for different behavior for gameplay deaths vs. cleanup deaths.
          ent:ForceKill(false)
        end
      end
    end
  end
end

-- a player picked a hero!
function GameMode:OnPickNewHero(event)
  print("OnPickNewHero called")
  -- Get the table that stores what each player has picked and add our new pick into it
  local picks
  picks = CustomNetTables:GetTableValue("gamestate", "new_hero_picks")
  print("old picks (if any):")
  PrintTable(picks)
  if picks == nil then
    picks = {}
  end
  picks[tostring(event.PlayerID)] = event.hero
  print("current picks:")
  PrintTable(picks)

  -- If we're the only player, we might as well just start the game.
  if PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) <= 1 then
    local newhero = "npc_dota_hero_" .. event.hero
    local player = 0
      -- Precache in case we haven't
      PrecacheUnitByNameAsync(newhero, function()
        local oldhero = PlayerResource:GetPlayer(player):GetAssignedHero()
        GameMode:KillCorrespondingSplitUnits(oldhero)
        local replaced = PlayerResource:ReplaceHeroWith(player, newhero, 0, 0)
        if not replaced then
          CreateHeroForPlayer(newhero, PlayerResource:GetPlayer(player))
        end
        oldhero:RemoveSelf()
      end)
    CustomNetTables:SetTableValue("gamestate", "new_hero_picks", {})  -- Clear this out so we can use it again for the next rematch
    print("This should be an empty table:")
    PrintTable(CustomNetTables:GetTableValue("gamestate", "new_hero_picks"))
    GameMode:Rematch()    -- Does more things
    return
  end

  -- See if all players have picked
  local have_all_players_picked = true
  for _,player in pairs(GetPlayersOnTeams({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS})) do
    if not picks[tostring(player:GetPlayerID())] then
      print(player:GetPlayerID())
      have_all_players_picked = false
    end
  end

  if have_all_players_picked then
    local players = GetPlayersOnTeams({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS})
    -- Create new heroes
    for k,player in pairs(players) do
      local newhero = "npc_dota_hero_" .. picks[tostring(player:GetPlayerID())]
      -- Precache in case we haven't
      PrecacheUnitByNameAsync(newhero, function()
        local oldhero = player:GetAssignedHero()
        GameMode:KillCorrespondingSplitUnits(oldhero)
        local replaced = PlayerResource:ReplaceHeroWith(player:GetPlayerID(), newhero, 0, 0)
        if not replaced then
          CreateHeroForPlayer(newhero, player)
        end
        oldhero:RemoveSelf()
      end)
    end
    CustomNetTables:SetTableValue("gamestate", "new_hero_picks", {})	-- Clear this out so we can use it again for the next rematch
    print("This should be an empty table:")
    PrintTable(CustomNetTables:GetTableValue("gamestate", "new_hero_picks"))
    GameMode:Rematch()		-- Does more things
  else
    CustomNetTables:SetTableValue("gamestate", "new_hero_picks", picks)
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(event.PlayerID), "opponent_didnt_pick_yet", {})
  end
end

function GameMode:Rematch()
  -- Set up the rematch
  match_count = match_count + 1
  round_times = {}
  hero_time = {}
  split_time = {}
  last_forM_change = {}
  CustomNetTables:SetTableValue("gamestate", "round", {"0"})
  CustomNetTables:SetTableValue("gamestate", "score", {[tostring(DOTA_TEAM_GOODGUYS)] = "0", [tostring(DOTA_TEAM_BADGUYS)] = "0"})
  GameMode:CompleteRound()		-- Set up the next round as usual. From here, we re-enter the usual round start/end logic.
end

function GameMode:IsGameplay()
  local result = CustomNetTables:GetTableValue("gamestate", "status")
  if result then
    return result["1"] == "gameplay"
  else
    return nil
  end
end

function GameMode:ConsoleForceEndgame(team)
  if tonumber(team) then
    GameMode:DeclareWinner(tonumber(team))
  else
    GameMode:DeclareWinner(DOTA_TEAM_GOODGUYS)
  end
end

function GameMode:ConsolePickHero(hero)
  local oldhero = PlayerResource:GetPlayer(0):GetAssignedHero()
  PrecacheUnitByNameAsync("npc_dota_hero_" .. hero, function()
    PlayerResource:ReplaceHeroWith(0, "npc_dota_hero_" .. hero, 0, 0)
    oldhero:RemoveSelf()
  end)
end

function GameMode:CreateFakeHero(event)
  if PlayerResource:GetPlayer(event.PlayerID):GetAssignedHero() == nil then
    print("creating fake hero for player " .. event.PlayerID .. " via cover screen")
    local fakehero = CreateHeroForPlayer("npc_dota_hero_wisp", PlayerResource:GetPlayer(event.PlayerID))
    fakehero:RespawnHero(false, false, false)
  end
end

function GameMode:BotPickHero(hero, player)
  if player then
    GameMode:OnPickNewHero({PlayerID = tonumber(player), hero = hero})
  else
    GameMode:OnPickNewHero({PlayerID = 1, hero = hero})
  end
end

function GameMode:BotRematchYes(player)
  if player then
    GameMode:OnRematchYes({PlayerID = player, player = player})
  else
    GameMode:OnRematchYes({PlayerID = 1, player = 1})
  end
end

function GameMode:BotRematchNo()
  GameMode:OnRematchNo({PlayerID = 1})
end

function GameMode:BotChangeHero(hero, player)
  if not player then
    local player = 1
  else
    player = tonumber(player)
  end
  local oldhero = PlayerResource:GetPlayer(player):GetAssignedHero()
  PrecacheUnitByNameAsync("npc_dota_hero_" .. hero, function()
    PlayerResource:ReplaceHeroWith(player, "npc_dota_hero_" .. hero, 0, 0)
    oldhero:RemoveSelf()
  end)
end

function GameMode:EndFormCounter(hero)
  local player = hero:GetPlayerOwner()
  local change = last_form_change[player]
  if change then
    if change.form == "hero" then
      local old_time = hero_time[player]
      if not old_time then
        old_time = 0
      end
      hero_time[player] = GameRules:GetGameTime() - change.time + old_time
      print(player:GetPlayerID() .. " hero time is now " .. hero_time[player])
    elseif change.form == "split" then
      local old_time = split_time[player]
      if not old_time then
        old_time = 0
      end
      split_time[player] = GameRules:GetGameTime() - change.time + old_time
      print(player:GetPlayerID() .. " split time is now " .. split_time[player])
    end
    last_form_change[player] = nil
  end
end