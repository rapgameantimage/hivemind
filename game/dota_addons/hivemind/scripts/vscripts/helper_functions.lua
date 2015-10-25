function DistanceBetweenVectors(v1, v2)
	return math.sqrt((v1.x - v2.x)^2 + (v1.y - v2.y)^2)
end

function DirectionFromAToB(a, b)
	return ((b - a) * Vector(1, 1, 0)):Normalized()
end

-- String splitter. Source: http://lua-users.org/wiki/SplitJoin
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
   table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


DAMAGE_TYPE_NAME_LOOKUP = {
	[0] = "DAMAGE_TYPE_NONE",
	[1] = "DAMAGE_TYPE_PHYSICAL",
	[2] = "DAMAGE_TYPE_MAGICAL",
	[4] = "DAMAGE_TYPE_PURE",
	[7] = "DAMAGE_TYPE_ALL",
	[8] = "DAMAGE_TYPE_HP_REMOVAL",
}
DOTA_UNIT_TARGET_TEAM_NAME_LOOKUP = {
	[0] = "DOTA_UNIT_TARGET_NONE",
	[1] = "DOTA_UNIT_TARGET_FRIENDLY",
	[2] = "DOTA_UNIT_TARGET_ENEMY",
	[3] = "DOTA_UNIT_TARGET_BOTH",
	[4] = "DOTA_UNIT_TARGET_CUSTOM",
}

function SimpleAOE(info)
	-- Required parameters: caster, radius, center
	-- Required parameters for dealing damage: damage
	-- Required parameters for applying modifiers: modifier name

	-- Damage type defaults to magical
	-- Team filter defaults to enemies
	-- Unit type filter defaults to heroes + creeps
	-- Modifier duration defaults to forever
	
	-- Pull from table. Check also for alternate syntaxes.

	local caster = info.caster
	local team = info.team
	local radius = info.radius
	local center = info.center
	if center == nil then center = info.point end
	local teamfilter = info.teamfilter
	if teamfilter == nil then teamfilter = info.team_filter end
	local typefilter = info.typefilter
	if typefilter == nil then typefilter = info.type_filter end
	local flagfilter = info.flagfilter
	if flagfilter == nil then flagfilter = info.flag_filter end
	local damage = info.damage
	local damagetype = info.damagetype
	if damagetype == nil then damagetype = info.damage_type end
	local damageflags = info.damageflags
	if damageflags == nil then damageflags = info.damage_flags end
	local ability = info.ability
	local modifiers = info.modifiers
	if modifiers == nil and info.modifier ~= nil then
		modifiers = info.modifier
	end
	local debug = info.debug
	local customfilter = info.customfilter

	if debug == "verbose" then
		print("SimpleAOE received the following table: ")
		print("========================================")
		PrintTable(info)
		print("========================================")
	end

	-- Check for mistakes
	if caster == nil and team == nil then
		print("Error: SimpleAOE called with nil caster and team")
		return 
	elseif radius == nil then
		print("Error: SimpleAOE called with nil radius")
		return
	elseif radius == 0 then
		print("Error: SimpleAOE called with 0 radius (did you make a typo in your AbilitySpecial variable?)")
		return
	elseif center == nil then
		print("Error: SimpleAOE called with nil center")
		return
	end

	if damagetype ~= nil and (damage == nil or damage == 0) then
		print("Warning: SimpleAOE called with a damage type, but no damage")
	end
	if damagetype ~= nil and DAMAGE_TYPE_NAME_LOOKUP[damagetype] == nil then
		print("Warning: SimpleAOE called with unrecognized damage type")
	end
	if teamfilter ~= nil and DOTA_UNIT_TARGET_TEAM_NAME_LOOKUP[teamfilter] == nil then
		print("Warning: SimpleAOE called with unrecognized team filter")
	end


	-- Set intelligent defaults for non-required values
	if teamfilter == nil then
		-- Default team filter to enemies
		if debug then print("Defaulting team filter to DOTA_UNIT_TARGET_TEAM_ENEMY (2)") end
		teamfilter = DOTA_UNIT_TARGET_TEAM_ENEMY
	end
	if typefilter == nil then
		-- Default type filter to heroes and creeps
		if debug then print("Defaulting type filter to DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC (19)") end
		typefilter = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	end
	if flagfilter == nil then
		-- Default flag filter to nothing
		if debug then print("Defaulting flag filter to DOTA_UNIT_TARGET_FLAG_NONE (0)") end
		flagfilter = DOTA_UNIT_TARGET_FLAG_NONE
	end
	if team == nil then
		-- Default search team to caster's team (very rare that we would want this to be anything else really)
		-- doesn't seem worth bothering to print a debug about?
		team = caster:GetTeam()
	end
	if damagetype == nil then
		-- Default damage type to magical
		if debug then print("Defaulting damage type to DAMAGE_TYPE_MAGICAL (2)") end
		damagetype = DAMAGE_TYPE_MAGICAL
	end

	-- Find units
	if debug then print("Searching for units of type " .. typefilter .. " in a " .. radius .. " radius of " .. tostring(center) .. " (" .. DistanceBetweenVectors(caster:GetAbsOrigin(), center) .. " units from caster) with team filter " .. DOTA_UNIT_TARGET_TEAM_NAME_LOOKUP[teamfilter] .. " using flag " .. flagfilter) end
	local units = FindUnitsInRadius(team, center, nil, radius, teamfilter, typefilter, flagfilter, 0, false)

	if next(units) == nil then
		if debug then print("Couldn't find anyone.") end
		return
	end

	if customfilter ~= nil then
		for key,unit in pairs(units) do
			local result = customfilter(unit)
			if debug then
				print(unit:GetName() .. " (" .. unit:GetEntityIndex() .. ") " .. (result and "passed" or "failed") .. " the custom filter")
			end
			if not result then
				units[key] = nil
			end
		end
	end

	
	-- Damage!
	function SimpleAOEDamage()
		if damage then
			for key,unit in pairs(units) do
				if debug then
					local debugstr = ""
					if caster == nil then debugstr = "Unspecified caster" else debugstr = caster:GetUnitName() .. " (" .. caster:GetEntityIndex() .. ")" end
					debugstr = debugstr .. " is dealing " .. damage .. " " .. DAMAGE_TYPE_NAME_LOOKUP[damagetype] .. " damage to " .. unit:GetUnitName() .. " (" .. unit:GetEntityIndex() .. ")"
					if ability == nil then debugstr = debugstr .. " with no specified ability" else debugstr = debugstr .. " using " .. ability:GetName() end
					if damageflags ~= nil then debugstr = debugstr .. " and damage flag(s) " .. damageflags end
					print(debugstr)
				end
				ApplyDamage({
					victim = unit,
					attacker = caster,
					damage = damage,
					damage_type = damagetype,
					ability = ability,
					damage_flags = damageflags -- This will be nil 99% of the time, but that's still valid.
				})
			end
		end
	end

	-- Modifiers!
	function SimpleAOEModifiers()
		if modifiers then
			for name,data in pairs(modifiers) do
				for j,unit in pairs(units) do
					if debug then
						local debugstr = ""
						if caster == nil then debugstr = "Unspecified caster" else debugstr = caster:GetUnitName() .. " (" .. caster:GetEntityIndex() .. ")" end
						debugstr = debugstr .. " is applying " .. name .. " to " .. unit:GetUnitName() .. " (" .. unit:GetEntityIndex() .. ")"
						if ability == nil then debugstr = debugstr .. " with no specified ability" else debugstr = debugstr .. " using " .. ability:GetName() end
						if next(data) == nil then debugstr = debugstr .. " with no data table (N.B. this means the modifier has unlimited duration)" else debugstr = debugstr .. " with the following data table:" end
						print(debugstr)
						PrintTable(data)
					end
					unit:AddNewModifier(caster, ability, name, data)
				end
			end
		end
	end

	if info.modifiers_before_damage then
		SimpleAOEModifiers()
		SimpleAOEDamage()
	else
		SimpleAOEDamage()
		SimpleAOEModifiers()
	end
end

---

FilterManager = class({})
FilterManager.filters = {}
FilterManager.filter_index = 0

function FilterManager:AddFilter(filtertype, func, context)
	local index = FilterManager.filter_index
	FilterManager.filters[index] = {filtertype = filtertype, func = func, context = context}
	FilterManager.filter_index = FilterManager.filter_index + 1
	return index
end

function FilterManager:RemoveFilter(id)
	FilterManager.filters[id] = nil
end

function FilterManager:Init()
	if GameRules:GetGameModeEntity() then
		GameRules:GetGameModeEntity():SetExecuteOrderFilter(function(context, order)
			for k,filter in pairs(FilterManager.filters) do
				if filter.filtertype == "order" and not filter.func(context, order) then
					return false
				end
			end
			return true
		end, {})
	end
end

FilterManager:Init()



function GetPlayersOnTeam(team)
	local players = {}
	for i = 0,DOTA_MAX_PLAYERS do
		local p = PlayerResource:GetPlayer(i)
		if p then
			if p:GetTeam() == team then
				table.insert(players, p)
			end
		end
	end
	return players
end

function GetPlayersOnTeams(teams)
	local players = {}
	for _,team in pairs(teams) do
		local teamplayers = GetPlayersOnTeam(team)
		for _,player in pairs(teamplayers) do
			table.insert(players, player)
		end
	end
	return players
end