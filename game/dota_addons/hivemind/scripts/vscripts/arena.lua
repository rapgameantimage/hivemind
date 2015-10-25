-- This file controls the bounds of the play area.

Arena = class({})

SHRINK_AMOUNT = 128 * 3			-- Ideal for this to be a multiple of BLOCKER_SIZE.

BLOCKER_SIZE = 128				-- No way to adjust this as far as I can tell, so leave it alone.

ORIGINAL_BOUNDS = {
	max_x = 2048,
	min_x = -2048,
	max_y = 2048,
	min_y = -2048,
}

current_bounds = ORIGINAL_BOUNDS

MIN_BOUNDS = {
	max_x = 512,
	min_x = -512,
	max_y = 512,
	min_y = -512,
}

ARENA_SHRINK_TIMER = 75			-- The time in seconds between shrinks.

ARENA_TICK_TIMER = 0.25			-- The time in seconds between events send to clients about the arena's status to update the purple bar at the top.

WALL_VISUAL_BUFFER = 48

--[[ 
"Shrinks" the arena by filling the outside of it with blockers.

Takes the current bounds of the arena and reduces them on each side by SHRINK_AMOUNT.
Checks for units outside these bounds, then moves them inside.
Creates four rectangles around each side of the map, then covers those with point_simple_obstruction entities.
Then stores the new arena size in current_bounds, and calls the function to create particles.

https://www.youtube.com/watch?v=VOo3E6ZeGOo
]]-- 
function Arena:Shrink()
	print("Started Arena:Shrink()")
	local new_bounds = {
		max_x = current_bounds.max_x - SHRINK_AMOUNT,
		min_x = current_bounds.min_x + SHRINK_AMOUNT,
		max_y = current_bounds.max_y - SHRINK_AMOUNT,
		min_y = current_bounds.min_y + SHRINK_AMOUNT,
	}

	-- Make sure we are not shrinking the arena beyond MIN_BOUNDS
	if not Arena:CanArenaExpand() then
		return
	end

	Arena:DestroyWallParticles()

	--[[
	Before we set up the arena, we need to loop through existing units, see if they are outside the arena bounds, and move them inside if they are.
	We could just let this happen on its own through natural collision checking when the blockers spawn, but the issue is that they are spawned
	one by one, and collision is checked each time. This leads to undesirable behavior like units at the top left corner being "pushed" one
	blocker at a time all the way to the top right corner. So we do our own check instead.
	]]--
	local heroes = HeroList:GetAllHeroes()
	local creatures = Entities:FindAllByClassname("npc_dota_creature")
	local units = {}
	-- Combine the hero and creature tables
	for k,hero in pairs(heroes) do
		units[DoUniqueString("arena_hero_check")] = hero
	end
	for k,creature in pairs(creatures) do
		units[DoUniqueString("arena_creature_check")] = creature
	end
	-- Check for units that are outside the new arena's bounds
	for k,unit in pairs(units) do
		local origin = unit:GetAbsOrigin()
		local new_origin = Vector(origin.x, origin.y, origin.z) 	-- can't use new_origin = origin, because userdata are pointers!
		if origin.x > new_bounds.max_x then
			new_origin.x = new_bounds.max_x
		elseif origin.x < new_bounds.min_x then
			new_origin.x = new_bounds.min_x
		end
		if origin.y > new_bounds.max_y then
			new_origin.y = new_bounds.max_y
		elseif origin.y < new_bounds.min_y then
			new_origin.y = new_bounds.min_y
		end
		-- If we moved them... move them.
		if origin ~= new_origin then
			FindClearSpaceForUnit(unit, new_origin, false)
		end
	end

	-- Now spawn the blockers.

	local ents_to_spawn = {}

	-- Top rectangle
	for x = current_bounds.min_x + (BLOCKER_SIZE / 2), current_bounds.max_x, BLOCKER_SIZE do
		for y = new_bounds.max_y + (BLOCKER_SIZE / 2), current_bounds.max_y, BLOCKER_SIZE do
			-- Store each blocker in a table so we can spawn them all at once below.
			-- I'm not sure if this has any actual effect on performance but doing 1 API call instead of 500 seems better.
			table.insert(ents_to_spawn, {origin = Vector(x, y, 0), classname = "point_simple_obstruction"})
		end
	end
	
	-- Bottom rectangle
	for x = current_bounds.min_x + (BLOCKER_SIZE / 2), current_bounds.max_x, BLOCKER_SIZE do
		for y = current_bounds.min_y + (BLOCKER_SIZE / 2), new_bounds.min_y, BLOCKER_SIZE do
			table.insert(ents_to_spawn, {origin = Vector(x, y, 0), classname = "point_simple_obstruction"})
		end
	end
	
	-- Left rectangle
	for x = current_bounds.min_x + (BLOCKER_SIZE / 2), new_bounds.min_x, BLOCKER_SIZE do
		for y = new_bounds.min_y + (BLOCKER_SIZE / 2), new_bounds.max_y, BLOCKER_SIZE do
			table.insert(ents_to_spawn, {origin = Vector(x, y, 0), classname = "point_simple_obstruction"})
		end
	end
	
	-- Right rectangle
	for x = new_bounds.max_x + (BLOCKER_SIZE / 2), current_bounds.max_x, BLOCKER_SIZE do
		for y = new_bounds.min_y + (BLOCKER_SIZE / 2), new_bounds.max_y, BLOCKER_SIZE do
			table.insert(ents_to_spawn, {origin = Vector(x, y, 0), classname = "point_simple_obstruction"})
		end
	end

	-- Spawn blockers
	SpawnEntityListFromTableSynchronous(ents_to_spawn)

	CustomGameEventManager:Send_ServerToAllClients("arena_shrink", { old_bounds = current_bounds, new_bounds = new_bounds })

	current_bounds = new_bounds	

	Arena:SetParticles()

	return true
end

--[[
Creates some particles (which are the wall of replica particle, but with cull radius set to -1 so it always draws) to draw the boundary.
The particles aren't really kept track of in a particularly robust fashion right now, but it still seems to work okay.
Note that we offset the particles by WALL_VISUAL_BUFFER to account for collision, as it's strange for units to be able to put part of their bodies through the wall.
]]--
function Arena:SetParticles()
	top_wall_particle = ParticleManager:CreateParticle("particles/arena_wall.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(top_wall_particle, 0, Vector(current_bounds.min_x - WALL_VISUAL_BUFFER, current_bounds.max_y + WALL_VISUAL_BUFFER, 0))
	ParticleManager:SetParticleControl(top_wall_particle, 1, Vector(current_bounds.max_x + WALL_VISUAL_BUFFER, current_bounds.max_y + WALL_VISUAL_BUFFER, 0))

	bottom_wall_particle = ParticleManager:CreateParticle("particles/arena_wall.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(bottom_wall_particle, 0, Vector(current_bounds.min_x - WALL_VISUAL_BUFFER, current_bounds.min_y - WALL_VISUAL_BUFFER, 0))
	ParticleManager:SetParticleControl(bottom_wall_particle, 1, Vector(current_bounds.max_x + WALL_VISUAL_BUFFER, current_bounds.min_y - WALL_VISUAL_BUFFER, 0))

	left_wall_particle = ParticleManager:CreateParticle("particles/arena_wall.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(left_wall_particle, 0, Vector(current_bounds.min_x - WALL_VISUAL_BUFFER, current_bounds.min_y - WALL_VISUAL_BUFFER, 0))
	ParticleManager:SetParticleControl(left_wall_particle, 1, Vector(current_bounds.min_x - WALL_VISUAL_BUFFER, current_bounds.max_y + WALL_VISUAL_BUFFER, 0))

	right_wall_particle = ParticleManager:CreateParticle("particles/arena_wall.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(right_wall_particle, 0, Vector(current_bounds.max_x + WALL_VISUAL_BUFFER, current_bounds.min_y - WALL_VISUAL_BUFFER, 0))
	ParticleManager:SetParticleControl(right_wall_particle, 1, Vector(current_bounds.max_x + WALL_VISUAL_BUFFER, current_bounds.max_y + WALL_VISUAL_BUFFER, 0))
end

function Arena:DestroyWallParticles()
	if top_wall_particle then ParticleManager:DestroyParticle(top_wall_particle, false) end
	if bottom_wall_particle then ParticleManager:DestroyParticle(bottom_wall_particle, false) end
	if left_wall_particle then ParticleManager:DestroyParticle(left_wall_particle, false) end
	if right_wall_particle then ParticleManager:DestroyParticle(right_wall_particle, false) end
end

function Arena:Reset(restart_timer)
	Arena:DestroyWallParticles()
	Timers:RemoveTimer("arena_controller")
	Timers:RemoveTimer("arena_shrink_tick")
	for k,ent in pairs(Entities:FindAllByClassname("point_simple_obstruction")) do
		ent:Destroy()
	end
	current_bounds = ORIGINAL_BOUNDS
	if restart_timer then
		Arena:StartTimer()
	end
end

function Arena:StartTimer()
	shrink_timer_start_time = GameRules:GetGameTime()
	Timers:CreateTimer("arena_controller", {
		endTime = ARENA_SHRINK_TIMER,
		useGameTime = true,
		callback = function()
			if GameMode:IsGameplay() then
				Arena:Shrink()
				if Arena:CanArenaExpand() then
					shrink_timer_start_time = GameRules:GetGameTime()
					return ARENA_SHRINK_TIMER
				end
			end
		end,
	})
	Timers:CreateTimer("arena_shrink_tick", {
		end_time = ARENA_TICK_TIMER,
		useGameTime = true,
		callback = function ()
			if GameMode:IsGameplay() and Arena:CanArenaExpand() then
				CustomGameEventManager:Send_ServerToAllClients("arena_shrink_tick", {
					percent_elapsed = (GameRules:GetGameTime() - shrink_timer_start_time) / ARENA_SHRINK_TIMER
				})
				return ARENA_TICK_TIMER
			end
		end,
	})
end

function Arena:CanArenaExpand()			-- I think this should actually be called CanArenaShrink... Not sure what I was thinking exactly.
	local new_bounds = {
		max_x = current_bounds.max_x - SHRINK_AMOUNT,
		min_x = current_bounds.min_x + SHRINK_AMOUNT,
		max_y = current_bounds.max_y - SHRINK_AMOUNT,
		min_y = current_bounds.min_y + SHRINK_AMOUNT,
	}

	if new_bounds.max_x < MIN_BOUNDS.max_x or new_bounds.min_x > MIN_BOUNDS.min_x or new_bounds.max_y < MIN_BOUNDS.max_y or new_bounds.min_y > MIN_BOUNDS.min_y then
		return false
	else
		return true
	end
end

function Arena:IsLocationWithinBounds(loc)
	if loc.x > current_bounds.max_x or loc.x < current_bounds.min_x or loc.y > current_bounds.max_y or loc.y < current_bounds.min_y then
		return false
	else
		return true
	end
end

function Arena:MoveLocationWithinBounds(loc)
	local new_loc = Vector(loc.x, loc.y, loc.z)
	if loc.x > current_bounds.max_x then
		new_loc.x = current_bounds.max_x
	elseif loc.x < current_bounds.min_x then
		new_loc.x = current_bounds.min_x
	end

	if loc.y > current_bounds.max_y then
		new_loc.y = current_bounds.max_y
	elseif loc.y < current_bounds.min_y then
		new_loc.y = current_bounds.min_y
	end

	return loc
end