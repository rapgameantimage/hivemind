function GameMode:CreateSplitUnits(hero)
  print("Started CreateSplitUnits for " .. hero:GetUnitName())
  -- This flag happens during certain abilities, e.g. when creating illusions via CreateUnitByName
  local skip_status = CustomNetTables:GetTableValue("gamestate", "dont_create_split_units")
  if skip_status ~= nil then
    if skip_status["1"] ~= nil then
      return
    end
  end

  -- Set these tables in split_units_definitions.lua
  local num = NUMBER_OF_SPLIT_UNITS[hero:GetName()]
  local unitname = SPLIT_UNIT_NAMES[hero:GetName()]
  if num == nil or unitname == nil then
    print("Unable to find split unit data for " .. hero:GetName() .. "...?")
    return
  end
  local units = {}
  local entindexes = {}
  -- Create num split units
  for i = 1,num do
    -- Create a unit
    local unit = CreateUnitByName(SPLIT_UNIT_NAMES[hero:GetName()], Vector(0,0,0), true, hero, hero, hero:GetTeam())
    unit:SetControllableByPlayer(hero:GetPlayerOwnerID(), true)
    -- Hide it (because we always start in hero form)
    unit:AddNewModifier(unit, nil, "modifier_hidden", {})
    -- Create particles if needed
    local pfunc = SPLIT_UNIT_PARTICLE_FUNCTIONS[hero:GetName()]
    if pfunc then
      Timers:CreateTimer(0.03, function()
        pfunc(unit)
      end)
    end
    -- Store the entity index.
    -- Entity indexes aren't guaranteed to be assigned in ascending order, so let's wait until we know what indexes we have to assign the 1-X IDs that show up in the UI.
    table.insert(entindexes, unit:GetEntityIndex())
  end
  table.sort(entindexes) -- I think this might not be accomplishing anything? Not sure. Can't remember why I put it here.
  for i = 1,num do
    -- Assign friendly IDs to each unit (these are the numbers that appear in the sidebar portraits)
    units[entindexes[i]] = {id = i, unitname = unitname}
  end
  -- Save these in a nettable for later (will be referenced in Panorama as well as in the split/unify functions below)
  CustomNetTables:SetTableValue("split_units", tostring(hero:GetEntityIndex()), units)
  CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "split_units_created", {units=units, count=num}) -- Triggers a rebuild of the split sidebar panel
  print("Finished CreateSplitUnits for " .. hero:GetUnitName())
end


-- Gets called when a hero uses their split ability. All the work is done here.
function GameMode:SplitHero(ability, callback)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local facing = caster:GetForwardVector()
  local units = GameMode:GetSplitUnitsForHero(caster, false)

  CustomGameEventManager:Send_ServerToPlayer(player, "split_hero_started", {
    hero = caster:GetEntityIndex(),
    player = player,
    units = units,
    location = caster:GetAbsOrigin()
  })

  -- particles
  local splitting_fx = ParticleManager:CreateParticle("particles/split_source.vpcf", PATTACH_ABSORIGIN, caster)

  -- hide hero
  caster:AddNewModifier(caster, nil, "modifier_hidden", {})

  -- turn off toggle abilities, if any
  for i = 0, caster:GetAbilityCount() - 1 do
    local ab = caster:GetAbilityByIndex(i)
    if ab ~= nil then
      if ab:IsToggle() and ab:GetToggleState() then
        ab:ToggleAbility()
      end
    end
  end

  -- enable split position setting
  caster:SwapAbilities(ability:GetAbilityName(), "spread_units", false, true)

  -- stop us from losing vision (b/c we've just applied modifier_hidden, which removes all vision)
  AddFOWViewer(caster:GetTeam(), caster:GetAbsOrigin(), GameRules:IsDaytime() and caster:GetBaseDayTimeVisionRange() or caster:GetBaseNightTimeVisionRange(), SPLIT_DELAY, true)

  -- count living units
  local living_units = 0
  for k,v in pairs(units) do
    living_units = living_units + 1
  end

  -- calculate positions to place units at
  local center = caster:GetAbsOrigin()
  local radius = 150
  local points = living_units
  local start = RandomFloat(0, 2 * math.pi)   -- Randomize the orientation of the circle
  local positions = {}
  for k = 1,points do
    local x = center.x + radius * math.cos(start + 2 * k * math.pi / points)
    local y = center.y + radius * math.sin(start + 2 * k * math.pi / points)
    positions[k] = Vector(x, y, 0)
  end

  -- first loop through split units (still hidden)
  local unitcount = 1
  for k,unit in pairs(units) do
    if unit ~= nil then
      -- move near the hero. we have to do this now because if there isn't a delay of at least 1 tick between moving them and revealing them, the player sees them move.
      FindClearSpaceForUnit(unit, positions[unitcount], false)
      unit:Stop()
      unit:SetForwardVector(DirectionFromAToB(center, positions[unitcount]))

      unit:AddNewModifier(caster, ability, "modifier_splitting", {duration=SPLIT_DELAY})  -- Do it for the particles

      unitcount = unitcount + 1
    end
  end

  caster:AddNewModifier(caster, ability, "modifier_ok_to_complete_transformation", {})  -- This gets removed if a new round starts while we're splitting, so we know not to finish.

  -- wait a moment
  Timers:CreateTimer(SPLIT_DELAY, function()
  	-- Do this first in case the transformation turns out to be invalid
  	ParticleManager:DestroyParticle(splitting_fx, false)
  	caster:SwapAbilities(ability:GetAbilityName(), "spread_units", true, false)

    -- Check to see if it's ok to keep transforming
    if caster:HasModifier("modifier_ok_to_complete_transformation") then
      caster:RemoveModifierByName("modifier_ok_to_complete_transformation")
    else
      print("Cancelling invalid transformation")
      return
    end

    for k,unit in pairs(units) do
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

      -- in case we got stuck
      FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)

      -- enable/make visible
      unit:RemoveModifierByName("modifier_hidden")

      -- particles
      ParticleManager:CreateParticle("particles/split_flare.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    end

    CustomGameEventManager:Send_ServerToPlayer(player, "split_hero_finished", {
      hero = caster:GetEntityIndex(),
      player = player,
      units = units,
      location = caster:GetAbsOrigin()
    })

    -- use the callback if one was provided
    if callback then
      callback(ability)
    end

    -- start counting time spent in split form.
    last_form_change[player] = {form = "split", time = GameRules:GetGameTime()}
  end)

  -- update time spent in hero form. this happens BEFORE the delay above, since the timer acts as a fork.
  -- putting this at the bottom so that the whole game doesn't break if something goes wrong.
  if last_form_change[player] then
    local old_time = hero_time[player]
    local additional_time = GameRules:GetGameTime() - last_form_change[player].time
    if not old_time then
      old_time = 0
    end
    hero_time[player] = old_time + additional_time
  end
end

-- Gets called when a split unit uses their unify ability. All the work is done here.
function GameMode:UnifyHero(ability, callback)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local hero = player:GetAssignedHero()
  local units = GameMode:GetSplitUnitsForHero(hero, false)

  CustomGameEventManager:Send_ServerToPlayer(player, "unify_hero_started", {
    casting_unit = caster:GetEntityIndex(),
    player = player,
    hero = player:GetAssignedHero():GetEntityIndex(),
    units = units,
    location = caster:GetAbsOrigin()
  }) 

  local particles = {}

  -- hide split units
  for k,unit in pairs(units) do
    if unit ~= nil then
      -- particles; CP1 = the place they will be dragged to (the caster's location)
      -- Note, we need to place the particles before hiding, since they will be moved underground when hiding
      local pfx = ParticleManager:CreateParticle("particles/unify.vpcf", PATTACH_ABSORIGIN, unit)
      ParticleManager:SetParticleControl(pfx, 1, GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0, 0, 64))
      particles[unit] = pfx

      unit:Stop()
      unit:AddNewModifier(caster, nil, "modifier_hidden", {})
    end
  end

  -- stop us from losing vision (modifier_hidden removes all vision)
  AddFOWViewer(caster:GetTeam(), caster:GetAbsOrigin(), GameRules:IsDaytime() and caster:GetBaseDayTimeVisionRange() or caster:GetBaseNightTimeVisionRange(), SPLIT_DELAY, true)

  -- move the hero (see explanation in splithero of why we do this now)
  hero:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), hero))
  hero:SetForwardVector(caster:GetForwardVector())

  hero:AddNewModifier(hero, ability, "modifier_ok_to_complete_transformation", {}) -- again, see above.

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

    for k,pfx in pairs(particles) do
      ParticleManager:DestroyParticle(pfx, true)
    end

    -- use the callback if one was provided
    if callback then
      callback()
    end

    -- Start counting time spent in hero form
    last_form_change[player] = {form = "hero", time = GameRules:GetGameTime()}
  end)

  -- Update time spent in split form
  if last_form_change[player] then
    local old_time = split_time[player]
    local additional_time = GameRules:GetGameTime() - last_form_change[player].time
    if not old_time then
      old_time = 0
    end
    split_time[player] = old_time + additional_time
  end
end

-- Every hero's unify ability checks this cast filter.
function GameMode:UnifyHeroCastFilterResult(ability)
  local caster = ability:GetCaster()
  local player = caster:GetPlayerOwner()
  local hero = player:GetAssignedHero()
  local units = GameMode:GetSplitUnitsForHero(hero)

  for k,unit in pairs(units) do
    if unit ~= nil then
      -- I initially had a max distance on unify, but I actually kinda think the game is more interesting without one?
      -- It still works if you uncomment here and in UnifyHeroGetCustomCastError.
      if --[[DistanceBetweenVectors(caster:GetAbsOrigin(), unit:GetAbsOrigin()) > MAX_RADIUS_FOR_UNIFY or]] unit:HasModifier("modifier_dimensional_bind") then
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
  local units = GameMode:GetSplitUnitsForHero(hero)

  for k,unit in pairs(units) do
    if unit ~= nil then
      --[[if DistanceBetweenVectors(caster:GetAbsOrigin(), unit:GetAbsOrigin()) > MAX_RADIUS_FOR_UNIFY then
        return "#dota_hud_error_units_too_far_to_unify"
      else]]if unit:HasModifier("modifier_dimensional_bind") then
        return "#dota_hud_error_dimensional_bind_split"
      end
    end
  end
end

-- Every hero's split ability checks this cast filter.
function GameMode:SplitHeroCastFilterResult(ability)
  local do_units_exist = false
  print(ability:GetCaster():GetUnitName() .. " wants to split")
  for _,unit in pairs(GameMode:GetSplitUnitsForHero(ability:GetCaster())) do
  	do_units_exist = true
  	break
  end
  if not do_units_exist then
  	print("Uh oh, " .. ability:GetCaster():GetUnitName() .. " just tried to split to a group that doesn't exist?")
  	return UF_FAIL_CUSTOM
  end
  if ability:GetCaster():HasModifier("modifier_dimensional_bind") then
    return UF_FAIL_CUSTOM
  else
    return UF_SUCCESS
  end
end

function GameMode:SplitHeroGetCustomCastError(ability)
	if ability:GetCaster():HasModifier("modifier_dimensional_bind") then
  		return "#dota_hud_error_dimensional_bind_hero"
  	else
  		-- For if we can't find any split units.
  		return "#dota_hud_error_hidden"	
  	end
end

-- Mainly for when heroes die or for when we're resetting the game.
function GameMode:KillCorrespondingSplitUnits(hero)
  local units = GameMode:GetSplitUnitsForHero(hero)
  CustomNetTables:SetTableValue("gamestate", "ignore_split_unit_death", {[tostring(hero:GetEntityIndex())] = true})     -- Needed to avoid an infinite loop...
  if units ~= nil then
    for k,unit in pairs(units) do
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

function GameMode:GetSplitUnitsForHero(hero, include_dead)
  local data = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))
  local units = {}
  for index,info in pairs(data) do
    if not info.dead or include_dead then
      table.insert(units, EntIndexToHScript(tonumber(index)))
    end
  end
  return units
end