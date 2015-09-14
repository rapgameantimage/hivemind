sticky_flame = class({})
LinkLuaModifier("modifier_sticky_flame", "heroes/phoenix/modifier_sticky_flame", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sticky_flame_projectile", "heroes/phoenix/modifier_sticky_flame_projectile", LUA_MODIFIER_MOTION_NONE)

function sticky_flame:OnSpellStart()
	local caster = self:GetCaster()
	local radius = 25
	local arc_height = 512
	local origin = caster:GetAbsOrigin()
	local finish = self:GetCursorPosition()
	local lifetime = self:GetSpecialValueFor("projectile_duration")
	local xy_distance = DistanceBetweenVectors(finish, origin)
	local xy_direction = ((finish - origin) * Vector(1,1,0)):Normalized()
	local z_velocity = Vector(0, 0, arc_height * 2 / lifetime)

	-- used mainly in arc below
	local step = 0
	local step_duration = 0.1
	local step_pct_traveled = {.05, .07, .11, .13, .14, .14, .13, .11, .07, .05}
	local step_pct_height_traveled = {.18, .14, .11, .07, 0, 0, .07, .11, .14, .18}

	self.projectile = CreateUnitByName("npc_dota_sticky_flame_dummy", origin, false, caster, caster, caster:GetTeam())
	self.projectile:AddNewModifier(caster, self, "modifier_sticky_flame_projectile", {})
	Physics:Unit(self.projectile)
	self.projectile:FollowNavMesh(false)
	self.projectile:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	self.projectile:SetAutoUnstuck(false)
	self.projectile:SetPhysicsFriction(0)

	StartSoundEvent("Hero_Phoenix.FireSpirits.Launch", caster)

	-- simulates an arc over 10 "steps"
	-- this might have been easier to do with a formula of some kind... but it's been a while since high school physics...
	Timers:CreateTimer(0, function()
		step = step + 1
		if step <= 10 then
			local xy_velocity = xy_direction * xy_distance * step_pct_traveled[step] / step_duration
			local z_velocity = Vector(0, 0, arc_height * 2 * step_pct_height_traveled[step] / step_duration)
			if step >= 6 then
				z_velocity = z_velocity * Vector(1, 1, -1)
			end
			self.projectile:SetPhysicsVelocity(xy_velocity + z_velocity)
			return 0.1
		else
			self:Impact()
		end
	end)
end

function sticky_flame:Impact()
	ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.projectile)
	StartSoundEvent("Hero_Phoenix.ProjectileImpact", self:GetCaster())

	local max_dps = self:GetSpecialValueFor("max_dps")
	local max_slow = self:GetSpecialValueFor("max_slow")
	local radius = self:GetSpecialValueFor("radius")
	local units = FindUnitsInRadius(self:GetCaster():GetTeam(), self.projectile:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for i,unit in pairs(units) do
		local this_unit_distance = DistanceBetweenVectors(unit:GetAbsOrigin(), self.projectile:GetAbsOrigin())
		local this_unit_stacks = ( radius - this_unit_distance + 20 ) / radius * 100
		if this_unit_stacks > 100 then this_unit_stacks = 100 end
		unit:AddNewModifier(self:GetCaster(), self, "modifier_sticky_flame", {duration = self:GetSpecialValueFor("duration")})
		unit:FindModifierByName("modifier_sticky_flame"):SetStackCount(this_unit_stacks)
	end

	self.projectile:AddNoDraw()
	self.projectile:ForceKill(false)
end