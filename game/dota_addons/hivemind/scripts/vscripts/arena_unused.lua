--[[
function Arena:Initialize()
	CORNER_TOP_LEFT = 1
	CORNER_TOP_RIGHT = 2
	CORNER_BOTTOM_LEFT = 3
	CORNER_BOTTOM_RIGHT = 4

	local corners = {}

	local topleft = CreateUnitByName("npc_arena_corner", Vector(current_bounds.min_x, current_bounds.max_y, 0), false, nil, nil, DOTA_TEAM_NOTEAM)
	topleft:SetIntAttr("corner", CORNER_TOP_LEFT)
	table.insert(corners, topleft)
	local bottomleft = CreateUnitByName("npc_arena_corner", Vector(current_bounds.min_x, current_bounds.min_y, 0), false, nil, nil, DOTA_TEAM_NOTEAM)
	topleft:SetIntAttr("corner", CORNER_BOTTOM_LEFT)
	table.insert(corners, bottomleft)
	local topright = CreateUnitByName("npc_arena_corner", Vector(current_bounds.max_x, current_bounds.max_y, 0), false, nil, nil, DOTA_TEAM_NOTEAM)
	topleft:SetIntAttr("corner", CORNER_TOP_RIGHT)
	table.insert(corners, topright)
	local bottomright = CreateUnitByName("npc_arena_corner", Vector(current_bounds.max_x, current_bounds.min_y, 0), false, nil, nil, DOTA_TEAM_NOTEAM)
	topleft:SetIntAttr("corner", CORNER_BOTTOM_RIGHT)
	table.insert(corners, bottomright)

	for _,corner in pairs(corners) do
		corner:AddNewModifier(corner, nil, "modifier_place_wall_particles", {})
	end

	ARENA_INITIALIZED = true
end

function Arena:GetCornerEntity(corner)
	for _,ent in pairs(Entities:FindAllByClassname("npc_dota_base_additive")) do
		if ent:GetIntAttr("corner") == corner then
			return ent
		end
	end
end

LinkLuaModifier("modifier_place_wall_particles", "arena", LUA_MODIFIER_MOTION_NONE)
modifier_place_wall_particles = class({})

function modifier_place_wall_particles:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()
	local corner = parent:GetIntAttr("corner")
	print(corner)

	local particle = ParticleManager:CreateParticle("particles/arena_wall.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
	if corner == CORNER_TOP_LEFT then
		ParticleManager:SetParticleControl(particle, 1, Arena:GetCornerEntity(CORNER_TOP_RIGHT):GetAbsOrigin())
	elseif corner == CORNER_TOP_RIGHT then
		ParticleManager:SetParticleControl(particle, 1, Arena:GetCornerEntity(CORNER_BOTTOM_RIGHT):GetAbsOrigin())
	elseif corner == CORNER_BOTTOM_RIGHT then
		ParticleManager:SetParticleControl(particle, 1, Arena:GetCornerEntity(CORNER_BOTTOM_LEFT):GetAbsOrigin())
	elseif corner == CORNER_BOTTOM_LEFT then
		ParticleManager:SetParticleControl(particle, 1, Arena:GetCornerEntity(CORNER_TOP_LEFT):GetAbsOrigin())
	end
end

function modifier_place_wall_particles:OnRefresh()
	self:OnCreated()
end

if not ARENA_INITIALIZED then
	Arena:Initialize()
end
]]

--[[
	Arena:GetCornerEntity(CORNER_TOP_LEFT):FindModifierByName("modifier_place_wall_particles"):ForceRefresh()
	Arena:GetCornerEntity(CORNER_TOP_LEFT):SetAbsOrigin(Vector(new_bounds.min_x, new_bounds.max_y, 0))
	Arena:GetCornerEntity(CORNER_TOP_RIGHT):FindModifierByName("modifier_place_wall_particles"):ForceRefresh()
	Arena:GetCornerEntity(CORNER_TOP_RIGHT):SetAbsOrigin(Vector(new_bounds.max_x, new_bounds.max_y, 0))
	Arena:GetCornerEntity(CORNER_BOTTOM_LEFT):FindModifierByName("modifier_place_wall_particles"):ForceRefresh()
	Arena:GetCornerEntity(CORNER_BOTTOM_LEFT):SetAbsOrigin(Vector(new_bounds.min_x, new_bounds.min_y, 0))
	Arena:GetCornerEntity(CORNER_BOTTOM_RIGHT):FindModifierByName("modifier_place_wall_particles"):ForceRefresh()
	Arena:GetCornerEntity(CORNER_BOTTOM_RIGHT):SetAbsOrigin(Vector(new_bounds.max_x, new_bounds.min_y, 0))
	]]
