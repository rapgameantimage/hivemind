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

-- My generalized stuff
require('helper_functions')

-- Hivemind-specific stuff
require('split_unit_definitions')
require('split_logic')
require('arena')

MAX_RADIUS_FOR_UNIFY = 800
SPLIT_DELAY = 0.5
UNIFY_DELAY = 0.5

KILLS_TO_WIN = 5
POST_ROUND_DELAY = 5 -- Also set this in main.js

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

  VectorTarget:Init()

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
  Convars:RegisterCommand( "pickhero", Dynamic_Wrap(GameMode, "ConsolePickHero"), "", FCVAR_CHEAT )

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')

  CustomNetTables:SetTableValue("gamestate", "round", {0})
  CustomNetTables:SetTableValue("gamestate", "score", {[tostring(DOTA_TEAM_GOODGUYS)] = "0", [tostring(DOTA_TEAM_BADGUYS)] = "0"})
  CustomNetTables:SetTableValue("gamestate", "ignore_split_unit_death", {})

  CustomGameEventManager:RegisterListener("rematch_yes", Dynamic_Wrap(GameMode, 'OnRematchYes'))
  CustomGameEventManager:RegisterListener("move_camera", Dynamic_Wrap(GameMode, 'MoveCamera'))
  CustomGameEventManager:RegisterListener("new_hero_picked", Dynamic_Wrap(GameMode, 'OnPickNewHero'))
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
  Convars:RegisterCommand( "pickhero", Dynamic_Wrap(GameMode, "ConsolePickHero"), "", FCVAR_CHEAT )
end

function GameMode:SetKillsToWin(kills)
  if tonumber(kills) then
    KILLS_TO_WIN = tonumber(kills)
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
  if currentround == nil then
    CustomNetTables:SetTableValue("gamestate", "round", { 1 })
  else
    CustomNetTables:SetTableValue("gamestate", "round", { tonumber(currentround["1"]) + 1 })
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
        hero:SwapAbilities(GameMode:FindSplitAbilityForHero(hero), "set_spawn_point", true, false)
      end
      if hero:HasModifier("modifier_hidden") then
        hero:RemoveModifierByName("modifier_hidden")
      end
      GameMode:KillCorrespondingSplitUnits(hero)

      -- Actually recreate the hero
      hero:Purge(true, true, false, true, true)
      for i = 0,hero:GetAbilityCount() - 1 do
        local ability = hero:GetAbilityByIndex(i)
        if ability ~= nil then ability:EndCooldown() end
      end
      hero:RespawnHero(false, false, false) -- wtf do these args do???
    end)
  end

  -- Triggers the "ROUND X" text in main.js
  CustomGameEventManager:Send_ServerToAllClients("round_started", {round = currentround})
end

function GameMode:DeclareWinner(team)
  CustomGameEventManager:Send_ServerToAllClients("match_completed", {winning_team = team})
  CustomNetTables:SetTableValue("gamestate", "winning_team", { tostring(team) })
  CustomNetTables:SetTableValue("gamestate", "status", { "finished" })
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
  -- Get the table that stores what each player has picked and add our new pick into it
  local picks
  picks = CustomNetTables:GetTableValue("gamestate", "new_hero_picks")
  if picks == nil then
    picks = {}
  end
  picks[tostring(event.PlayerID)] = event.hero

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
    GameMode:Rematch()    -- Does more things
  end

  -- See if both players have picked
  if picks[tostring(PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 1))] and picks[tostring(PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, 1))] then
    local players = {PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 1), PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, 1)}
    -- Create new heroes
    for k,player in pairs(players) do
      local newhero = "npc_dota_hero_" .. picks[tostring(player)]
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
    end
    CustomNetTables:SetTableValue("gamestate", "new_hero_picks", {})	-- Clear this out so we can use it again for the next rematch
    GameMode:Rematch()		-- Does more things
  else
    CustomNetTables:SetTableValue("gamestate", "new_hero_picks", picks)
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(event.PlayerID), "opponent_didnt_pick_yet", {})
  end
end

function GameMode:Rematch()
  -- Set up the rematch
  --[[
  for i = 0,PlayerResource:GetPlayerCount() - 1 do
    local hero = PlayerResource:GetPlayer(i):GetAssignedHero()
    if hero ~= nil then
      hero:Destroy()
    end
  end
  ]]
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
  PrecacheUnitByNameAsync("npc_dota_hero_" .. hero, function()
    PlayerResource:ReplaceHeroWith(0, "npc_dota_hero_" .. hero, 0, 0)
  end)
end