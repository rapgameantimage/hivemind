swoop = class({})
LinkLuaModifier("modifier_swoop_burning", "heroes/phoenix/modifier_swoop_burning", LUA_MODIFIER_MOTION_NONE)

function swoop:OnSpellStart()
	self.caster = self:GetCaster()
	self.origin = self.caster:GetAbsOrigin()
	self.target = self:GetCursorPosition()
	self.direction = ((self.target - self.origin) * Vector(1,1,0)):Normalized()
	self.speed = self:GetSpecialValueFor("speed")
	self.velocity = self.speed * self.direction
	self.distance = self:GetSpecialValueFor("distance")
	self.duration = self.distance / self.speed
	self.radius = self:GetSpecialValueFor("radius")
	self.team = self.caster:GetTeam()
	self.burn_duration = self:GetSpecialValueFor("burn_duration")

	-- Start movement
	self.caster:Stop()
	if not IsPhysicsUnit(self.caster) then Physics:Unit(self.caster) end
	self.caster:PreventDI(true)
	self.caster:FollowNavMesh(false)
	self.caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	self.caster:SetAutoUnstuck(false)
	self.caster:SetPhysicsFriction(0)
	self.caster:AddPhysicsVelocity(self.velocity)

	self.particles = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_icarus_dive.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	StartSoundEvent("Hero_Phoenix.IcarusDive.Cast", self.caster)

	self.start_time = GameRules:GetGameTime()
	Timers:CreateTimer(0.03, function()
		local time_elapsed = GameRules:GetGameTime() - self.start_time
		self.caster:SetForwardVector(self.direction) -- in case the player has been spinning around. we can't have any of that silliness in our swoops here. we run a serious business.

		if self.caster:HasModifier("modifier_hidden") or self.caster:IsStunned() then
			self:EndSwoop()
			return
		end

		local currentlocation = self.caster:GetAbsOrigin()

		GridNav:DestroyTreesAroundPoint(currentlocation, self.radius, false)

		local groundheight = GetGroundHeight(currentlocation, self.caster)
		if currentlocation.z > groundheight then
			currentlocation.z = groundheight
			self.caster:SetAbsOrigin(currentlocation)
		end
		if self.egg ~= nil then
			local egglocation = self.egg:GetAbsOrigin()
			local egg_groundheight = GetGroundHeight(egglocation, self.egg)
			if egglocation.z > egg_groundheight then
				egglocation.z = egg_groundheight
				self.egg:SetAbsOrigin(egglocation)
			end
		end


		-- See if there are any enemies nearby that we haven't already hit
		local enemies = FindUnitsInRadius(self.team, currentlocation, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
		for k,unit in pairs(enemies) do
			if not unit:HasModifier("modifier_swoop_burning") then
				unit:AddNewModifier(self.caster, self, "modifier_swoop_burning", {duration = self.burn_duration})
			end
		end

		-- See if we're done swoopin'
		if time_elapsed >= self.duration then
			self:EndSwoop()
			return
		elseif time_elapsed >= self.duration * 0.8 then
			if self.caster:GetPhysicsFriction() == 0 then
				self.caster:SetPhysicsFriction(0.2)
			end
			if self.egg ~= nil then
				if self.egg:GetPhysicsFriction() == 0 then
					self.egg:SetPhysicsFriction(0.2)
				end
			end
		end

		-- See if there are any eggs nearby to grab
		if self.egg == nil then
			local entities = Entities:FindAllByNameWithin("npc_dota_creature", currentlocation, self.radius)
			for k,ent in pairs(entities) do
				if ent:GetUnitName() == "npc_dota_fiery_birth_egg" then
					self.egg = ent
					-- Put it just behind the hero, and drag it along with us
					self.egg:SetAbsOrigin(currentlocation + (self.direction * Vector(-50, -50, 0)))
					if not IsPhysicsUnit(self.egg) then Physics:Unit(self.egg) end
					self.egg:SetPhysicsVelocity(self.velocity)
					self.egg:SetPhysicsFriction(0)
					self.egg:FollowNavMesh(false)
					self.egg:SetAutoUnstuck(false)
					break
				end
			end
		end
		return 0.03
	end)
end

function swoop:EndSwoop()
	self.caster:PreventDI(false)
	self.caster:FollowNavMesh(true)
	self.caster:SetPhysicsVelocity(Vector(0,0,0))
	if self.egg ~= nil then
		if not self.egg:IsNull() then
			self.egg:SetPhysicsVelocity(Vector(0,0,0))
			self.egg:FollowNavMesh(true)
			FindClearSpaceForUnit(self.egg, self.egg:GetAbsOrigin(), false)
		end
		self.egg = nil
	end
	FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), false)
	ParticleManager:DestroyParticle(self.particles, false)
	StartAnimation(self.caster, {activity = ACT_DOTA_TELEPORT, duration = 1})
end

function swoop:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end