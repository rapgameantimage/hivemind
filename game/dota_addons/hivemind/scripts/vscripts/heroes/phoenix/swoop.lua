--[[
Basically all the work here is done in modifier_swoop, and particularly its think function.
Originally I didn't use a modifier for this, but I switched it to work this way to take advantage of modifiers'
reliable duration, particle destruction, etc. even if something else happens to go wrong.
]]


swoop = class({})

function swoop:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_swoop", {duration = self:GetSpecialValueFor("distance") / self:GetSpecialValueFor("speed")})
	self:GetCaster():EmitSound("Hero_Phoenix.IcarusDive.Cast")
end

function swoop:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

---

LinkLuaModifier("modifier_swoop", "heroes/phoenix/swoop", LUA_MODIFIER_MOTION_NONE)
modifier_swoop = class({})

function modifier_swoop:OnCreated()
	if not IsServer() then return end
	-- Configuration
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.origin = self.caster:GetAbsOrigin()
	self.target = self.ability:GetCursorPosition()
	self.direction = ((self.target - self.origin) * Vector(1,1,0)):Normalized()
	self.speed = self.ability:GetSpecialValueFor("speed")
	self.velocity = self.speed * self.direction
	self.distance = self.ability:GetSpecialValueFor("distance")
	self.duration = self.distance / self.speed
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.team = self.caster:GetTeam()
	self.burn_duration = self.ability:GetSpecialValueFor("burn_duration")

	-- make sure the caster is facing the right direction -- in case they turned to cast this and the turn didn't finish
	self.caster:SetForwardVector(self.direction)

	-- Start movement
	self.caster:Stop()
	if not IsPhysicsUnit(self.caster) then Physics:Unit(self.caster) end
	self.caster:FollowNavMesh(false)
	self.caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	self.caster:SetAutoUnstuck(false)
	self.caster:SetPhysicsFriction(0)
	self.caster:AddPhysicsVelocity(self.velocity)

	self.start_time = GameRules:GetGameTime()

	-- We'll need to check our surroundings every tick
	self.think_interval = 0.03
	self:StartIntervalThink(self.think_interval)
end

function modifier_swoop:OnIntervalThink()
	if not IsServer() then return end
	local time_elapsed = GameRules:GetGameTime() - self.start_time

	local currentlocation = self.caster:GetAbsOrigin()

	GridNav:DestroyTreesAroundPoint(currentlocation, self.radius, false)

	-- See if we changed elevation
	local groundheight = GetGroundHeight(currentlocation, self.caster)
	if currentlocation.z > groundheight then
		currentlocation.z = groundheight
		self.caster:SetAbsOrigin(currentlocation)
	end
	-- See if the egg changed elevation
	if self.egg ~= nil and not self.egg:IsNull() then
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
			unit:AddNewModifier(self.caster, self.ability, "modifier_swoop_burning", {duration = self.burn_duration})
		end
	end

	-- See if we need to stop swoopin'
	if time_elapsed >= self.duration or self.caster:HasModifier("modifier_hidden") or self.caster:IsStunned() then
		self:Destroy()
		return
	-- If the end is nigh, apply some friction so it doesn't look so abrupt and mechanical when it stops
	elseif time_elapsed >= self.duration * 0.8 then
		if self.caster:GetPhysicsFriction() == 0 then
			self.caster:SetPhysicsFriction(0.2)
		end
		if self.egg ~= nil and not self.egg:IsNull() then
			if self.egg:GetPhysicsFriction() == 0 then
				self.egg:SetPhysicsFriction(0.2)
			end
		end
	end

	-- See if there are any eggs nearby to grab
	if self.egg == nil then
		local entities = Entities:FindAllByNameWithin("npc_dota_creature", currentlocation, self.radius)
		for k,ent in pairs(entities) do
			-- Check that it's an egg, and that it's our egg
			if ent:GetUnitName() == "npc_dota_fiery_birth_egg" and ent:GetTeam() == self.team then
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
end

function modifier_swoop:OnDestroy()
	if not IsServer() then return end
	self.caster:FollowNavMesh(true)
	self.caster:SetPhysicsVelocity(Vector(0,0,0))
	self.caster:SetPhysicsFriction(0.05)
	if self.egg ~= nil then
		if not self.egg:IsNull() then
			self.egg:SetPhysicsVelocity(Vector(0,0,0))
			self.egg:FollowNavMesh(true)
			FindClearSpaceForUnit(self.egg, self.egg:GetAbsOrigin(), false)
		end
		self.egg = nil
	end
	FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), false)
	StartAnimation(self.caster, {activity = ACT_DOTA_TELEPORT, duration = 1})
end

function modifier_swoop:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_swoop:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_icarus_dive.vpcf"
end

function modifier_swoop:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_swoop:DeclareFunctions()
	return {MODIFIER_PROPERTY_DISABLE_TURNING}
end

function modifier_swoop:GetModifierDisableTurning()
	return 1    -- we can't have any of this silly spinning around in our ability. this is a very serious ability and we can't abide by that.
end

---

LinkLuaModifier("modifier_swoop_burning", "heroes/phoenix/swoop", LUA_MODIFIER_MOTION_NONE)
modifier_swoop_burning = class({})

function modifier_swoop_burning:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.dps = self.ability:GetSpecialValueFor("dps")
	self.parent = self:GetParent()
	self.caster = self.ability:GetCaster()
	self:StartIntervalThink(0.49)
end

function modifier_swoop_burning:OnIntervalThink()
	if not IsServer() then return end
	ApplyDamage({
		attacker = self.caster,
		victim = self.parent,
		damage = self.dps / 2,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self.ability
	})
end

function modifier_swoop_burning:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_icarus_dive_burn_debuff.vpcf"
end

function modifier_swoop_burning:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
