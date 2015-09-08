BAREBONES_DEBUG_SPEW = false

if GameMode == nil then
    DebugPrint( '[BAREBONES] creating barebones game mode' )
    _G.GameMode = class({})
end

require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/animations')
require('internal/gamemode')
require('internal/events')
require('settings')
require('events')
require('helper_functions')

require('split_unit_definitions')

MAX_RADIUS_FOR_UNIFY = 800
SPLIT_DELAY = 0.5
UNIFY_DELAY = 0.5

KILLS_TO_WIN = 5
POST_ROUND_DELAY = 5 -- Also set this in main.js


--[[
  This function should be used to set up Async precache calls at the beginning of the gameplay.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).

  This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function GameMode:PostLoadPrecache()
  DebugPrint("[BAREBONES] Performing Post-Load precache")    
  --PrecacheItemByNameAsync("item_example_item", function(...) end)
  --PrecacheItemByNameAsync("example_ability", function(...) end)

  --PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
  --PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
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

function GameMode:CreateSplitUnits(hero)
  local num = NUMBER_OF_SPLIT_UNITS[hero:GetName()]
  local unitname = SPLIT_UNIT_NAMES[hero:GetName()]
  if num == nil or unitname == nil then
    print("Unable to find split unit data for " .. hero:GetName() .. "...?")
    return
  end
  local units = {}
  local entindexes = {}
  for i = 1,num do
    local unit = CreateUnitByName(SPLIT_UNIT_NAMES[hero:GetName()], Vector(0,0,0), true, hero, hero, hero:GetTeam())
    unit:SetControllableByPlayer(hero:GetPlayerOwnerID(), true)
    unit:AddNewModifier(unit, nil, "modifier_hidden", {})
    -- Entity indexes aren't guaranteed to be assigned in ascending order, so let's wait until we know what numbers we have to assign friendly IDs.
    units[unit:GetEntityIndex()] = {}
    table.insert(entindexes, unit:GetEntityIndex())
  end
  table.sort(entindexes)
  for i = 1,num do
    -- God, there has to be a better way to do this
    units[entindexes[i]] = {id = i}
  end
  CustomNetTables:SetTableValue("split_units", tostring(hero:GetEntityIndex()), units)
  CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "split_units_created", {units=units, count=num})
  print("Finished CreateSplitUnits")
end

function GameMode:OnGameInProgress()
  GameMode:NewRound(first)
end

function GameMode:InitGameMode()
  GameMode = self
  DebugPrint('[BAREBONES] Starting to load Barebones gamemode...')

  GameMode:_InitGameMode()

  LinkLuaModifier("modifier_hidden", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_splitting", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_ok_to_complete_transformation", "modifiers", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_postmortem_damage_source", "modifiers", LUA_MODIFIER_MOTION_NONE)

  Convars:RegisterCommand( "test", Dynamic_Wrap(GameMode, 'test'), "For testing things", FCVAR_CHEAT )
  Convars:RegisterCommand( "completeround", Dynamic_Wrap(GameMode, 'CompleteRound'), "", FCVAR_CHEAT )
  Convars:RegisterCommand( "rths", Dynamic_Wrap(GameMode, 'rths'), "Reset to hero selection", FCVAR_CHEAT )
  Convars:RegisterCommand( "update_abilities", Dynamic_Wrap(GameMode, "UpdateAbilities"), "For testing abilities", FCVAR_CHEAT )

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')

  CustomNetTables:SetTableValue("gamestate", "round", {0})

  CustomGameEventManager:RegisterListener("rematch_yes", Dynamic_Wrap(GameMode, 'OnRematchYes'))
end

-- Reloads scripts and replaces the hero with itself in order. Intended for testing ability scripts.
function GameMode:UpdateAbilities()
  SendToConsole("script_reload")
  SendToConsole("cl_script_reload")
  for k,hero in pairs(HeroList:GetAllHeroes()) do
    PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), hero:GetClassname(), PlayerResource:GetGold(hero:GetPlayerID()), hero:GetCurrentXP())
    hero:Destroy()
  end
end

function GameMode:rths()
  GameRules:ResetToHeroSelection()
end

function GameMode:test()
  --...
end

function Hello()
  print("Hello")
end

-- Gets called when a hero uses their split ability
function GameMode:SplitHero(ability)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local facing = caster:GetForwardVector()
  local units = CustomNetTables:GetTableValue("split_units", tostring(caster:GetEntityIndex()))

  CustomGameEventManager:Send_ServerToPlayer(player, "split_hero_started", {
    hero = caster:GetEntityIndex(),
    player = player,
    units = units,
    location = caster:GetAbsOrigin()
  })

  -- hide hero
  caster:AddNewModifier(caster, nil, "modifier_hidden", {})
  local splitting_fx = ParticleManager:CreateParticle("particles/split_source.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

  -- enable split position setting
  caster:SwapAbilities(ability:GetAbilityName(), "set_spawn_point", false, true)

  for unit,info in pairs(units) do
    unit = EntIndexToHScript(tonumber(unit))
    if unit ~= nil then
      -- move near the hero
      FindClearSpaceForUnit(unit, caster:GetAbsOrigin() + RandomVector(200), false)
      unit:SetForwardVector(facing)

      unit:AddNewModifier(caster, ability, "modifier_splitting", {duration=SPLIT_DELAY})
    end
  end

  caster:AddNewModifier(caster, ability, "modifier_ok_to_complete_transformation", {})

  -- wait a moment
  Timers:CreateTimer(SPLIT_DELAY, function()
    -- Check to see if it's ok to keep transforming
    if caster:HasModifier("modifier_ok_to_complete_transformation") then
      caster:RemoveModifierByName("modifier_ok_to_complete_transformation")
    else
      print("Cancelling invalid transformation")
      return
    end

    for unit,info in pairs(units) do
      unit = EntIndexToHScript(tonumber(unit))
      -- put unify on cd
      for i = 0, unit:GetAbilityCount()-1 do
        local a = unit:GetAbilityByIndex(i)
        if a ~= nil then
          if a:GetName():find("unify") ~= nil then
            a:StartCooldown(a:GetCooldown(a:GetLevel()))
            break
          end
        end
      end

      unit:RemoveModifierByName("modifier_split_move_counter")
      -- in case we got stuck
      FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)

      -- enable/make visible
      unit:RemoveModifierByName("modifier_hidden")
      ParticleManager:DestroyParticle(splitting_fx, false)
      ParticleManager:CreateParticle("particles/split_flare.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    end

    CustomGameEventManager:Send_ServerToPlayer(player, "split_hero_finished", {
      hero = caster:GetEntityIndex(),
      player = player,
      units = units,
      location = caster:GetAbsOrigin()
    })

    caster:SwapAbilities(ability:GetAbilityName(), "set_spawn_point", true, false)
  end)
end

-- Gets called when a split unit uses their unify ability
function GameMode:UnifyHero(ability)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local hero = player:GetAssignedHero()
  local units = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))

  CustomGameEventManager:Send_ServerToPlayer(player, "unify_hero_started", {
    casting_unit = caster:GetEntityIndex(),
    player = player,
    hero = player:GetAssignedHero():GetEntityIndex(),
    units = units,
    location = caster:GetAbsOrigin()
  }) 

  -- hide split units
  for unit,info in pairs(units) do
    unit = EntIndexToHScript(tonumber(unit))
    if unit ~= nil then
      unit:Stop()
      unit:AddNewModifier(caster, nil, "modifier_hidden", {})

      -- particles; CP1 = the place they will be dragged to
      local pfx = ParticleManager:CreateParticle("particles/unify.vpcf", PATTACH_ABSORIGIN, unit)
      ParticleManager:SetParticleControl(pfx, 1, caster:GetAbsOrigin() + Vector(0, 0, 64))
    end
  end

  -- move the hero
  hero:SetAbsOrigin(caster:GetAbsOrigin())
  hero:SetForwardVector(caster:GetForwardVector())

  hero:AddNewModifier(hero, ability, "modifier_ok_to_complete_transformation", {})

  -- wait a moment
  Timers:CreateTimer(UNIFY_DELAY, function()
    if hero:HasModifier("modifier_ok_to_complete_transformation") then
      hero:RemoveModifierByName("modifier_ok_to_complete_transformation")
    else
      print("Cancelling invalid transformation")
      return
    end

    -- in case we got stuck
    FindClearSpaceForUnit(hero, hero:GetAbsOrigin(), false)

    -- enable hero
    hero:RemoveModifierByName("modifier_hidden")

    -- put split on cd
    for i = 0, hero:GetAbilityCount()-1 do
      local a = hero:GetAbilityByIndex(i)
      if a ~= nil then
        if a:GetName():find("split") ~= nil then
          a:StartCooldown(a:GetCooldown(a:GetLevel()))
          break
        end
      end
    end

    CustomGameEventManager:Send_ServerToPlayer(player, "unify_hero_finished", {
      casting_unit = caster:GetEntityIndex(),
      player = player,
      hero = player:GetAssignedHero():GetEntityIndex(),
      units = units,
      location = caster:GetAbsOrigin()
    }) 
  end)
end

function GameMode:UnifyHeroCastFilterResult(ability)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local hero = player:GetAssignedHero()
  local units = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))

  for unit,info in pairs(units) do
    unit = EntIndexToHScript(tonumber(unit))
    if unit ~= nil then
      if DistanceBetweenVectors(caster:GetAbsOrigin(), unit:GetAbsOrigin()) > MAX_RADIUS_FOR_UNIFY or unit:HasModifier("modifier_dimensional_bind") then
        return UF_FAIL_CUSTOM
      end
    end
  end
  return UF_SUCCESS
end

function GameMode:UnifyHeroGetCustomCastError(ability)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local hero = player:GetAssignedHero()
  local units = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))

  for unit,info in pairs(units) do
    unit = EntIndexToHScript(tonumber(unit))
    if unit ~= nil then
      if DistanceBetweenVectors(caster:GetAbsOrigin(), unit:GetAbsOrigin()) > MAX_RADIUS_FOR_UNIFY then
        return "#dota_hud_error_units_too_far_to_unify"
      elseif unit:HasModifier("modifier_dimensional_bind") then
        return "#dota_hud_error_dimensional_bind_split"
      end
    end
  end
end

function GameMode:SplitHeroCastFilterResult(ability)
  if ability:GetCaster():HasModifier("modifier_dimensional_bind") then
    return UF_FAIL_CUSTOM
  else
    return UF_SUCCESS
  end
end

function GameMode:SplitHeroGetCustomCastError(ability)
  return "#dota_hud_error_dimensional_bind_hero"
end

function GameMode:GetCurrentRound()
  return next(CustomNetTables:GetTableValue("gamestate", "round"))
end

function GameMode:NewRound()
  CustomNetTables:SetTableValue("gamestate", "status", { "gameplay" })
  local currentround = CustomNetTables:GetTableValue("gamestate", "round")
  if currentround == nil then
    CustomNetTables:SetTableValue("gamestate", "round", { 1 })
  else
    CustomNetTables:SetTableValue("gamestate", "round", { tonumber(currentround["1"]) + 1 })
  end
  for k,hero in pairs(HeroList:GetAllHeroes()) do
    if hero:HasModifier("modifier_ok_to_complete_transformation") then
      hero:RemoveModifierByName("modifier_ok_to_complete_transformation")
      hero:SwapAbilities(GameMode:FindSplitAbilityForHero(hero), "set_spawn_point", true, false)
    end
    if hero:HasModifier("modifier_hidden") then
      hero:RemoveModifierByName("modifier_hidden")
    end
    GameMode:KillCorrespondingSplitUnits(hero)
    hero:Purge(true, true, false, true, true)
    for i = 0,hero:GetAbilityCount() - 1 do
      local ability = hero:GetAbilityByIndex(i)
      if ability ~= nil then ability:EndCooldown() end
    end
    hero:RespawnHero(false, false, false) -- wtf do these args do
  end
end

function GameMode:CompleteRound()
  if GetTeamHeroKills(DOTA_TEAM_GOODGUYS) >= KILLS_TO_WIN then
    GameMode:DeclareWinner(DOTA_TEAM_GOODGUYS)
  elseif GetTeamHeroKills(DOTA_TEAM_BADGUYS) >= KILLS_TO_WIN then
    GameMode:DeclareWinner(DOTA_TEAM_BADGUYS)
  else
    CustomNetTables:SetTableValue("gamestate", "status", { "between_rounds" })
    Timers:CreateTimer(POST_ROUND_DELAY, function()
      GameMode:NewRound()
    end)
  end
end

function GameMode:DeclareWinner(team)
  CustomNetTables:SetTableValue("gamestate", "winning_team", { tostring(team) })
  CustomNetTables:SetTableValue("gamestate", "status", { "finished" })
  -- Panorama takes it from here.
end

function GameMode:KillCorrespondingSplitUnits(hero)
  local units = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))
  CustomNetTables:SetTableValue("gamestate", "ignore_split_unit_death", {[tostring(hero:GetEntityIndex())] = true})
  if units ~= nil then
    for index,info in pairs(units) do
      local unit = EntIndexToHScript(tonumber(index))
      if unit ~= nil then
        unit:ForceKill(false)
        unit:RemoveSelf()
      end
    end
    CustomNetTables:SetTableValue("split_units", tostring(hero:GetEntityIndex()), {})
  end
  CustomNetTables:SetTableValue("gamestate", "ignore_split_unit_death", {[tostring(hero:GetEntityIndex())] = nil})
end

function GameMode:FindSplitAbilityForHero(hero)
  for i = 0, hero:GetAbilityCount()-1 do
    local a = hero:GetAbilityByIndex(i)
    if a ~= nil then
      if a:GetName():find("split") ~= nil then
        return a
      end
    end
  end
end

function GameMode:Rematch()
  CustomNetTables:SetTableValue("gamestate", "rematch", {})
  CustomNetTables:SetTableValue("gamestate", "round", {"0"})
  CustomNetTables:SetTableValue("gamestate", "status", {"rematch"})
  for i = 0,PlayerResource:GetPlayerCount() - 1 do
    PlayerResource:GetPlayer(i):GetAssignedHero():ForceKill(false)
    PlayerResource:IncrementKills(i, PlayerResource:GetKills(i) * -1)  -- reset kill count
  end
  GameRules:ResetDefeated()
  GameRules:SetTimeOfDay( 0.0 )
  GameRules:ResetToHeroSelection()
end