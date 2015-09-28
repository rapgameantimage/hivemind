leap_strike = class({})

function leap_strike:OnSpellStart()
	-- config
	local leap_duration = .5

	local caster = self:GetCaster()
	local vector = self:GetCursorPosition()

	caster:AddNewModifier(caster, self, "modifier_leap_strike", {duration = leap_duration, target_x = vector.x, target_y = vector.y, target_z = vector.z, peak_height = peak_height})
	StartAnimation(caster, {duration = 0.6, activity = ACT_DOTA_ATTACK_EVENT, rate = 1})
end

function leap_strike:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

---

LinkLuaModifier("modifier_leap_strike", "heroes/wraith/leap_strike", LUA_MODIFIER_MOTION_NONE)
modifier_leap_strike = class({})

function modifier_leap_strike:OnCreated(info)
	if not IsServer() then return end
	self.old_pos = self:GetCaster():GetAbsOrigin()

	self.tick_rate = 0.03
	self.target = Vector(info.target_x, info.target_y, info.target_z)
	self.distance = DistanceBetweenVectors(self.old_pos, self.target)
	self.direction = DirectionFromAToB(self.old_pos, self.target)
	self.duration = self:GetDuration()
	self.horizontal_motion = self.direction * self.distance / self.duration
	self.vertical_force = Vector(0, 0, 3000)
	self.gravity = self.vertical_force.z * 2 * self.tick_rate / self.duration * -1
	self.caster = self:GetCaster()
	self.ticks = 0
	Physics:Unit(self.caster)
	self.caster:SetPhysicsFriction(0)
	self.caster:AddPhysicsVelocity(self.horizontal_motion + self.vertical_force)
	self.caster:FollowNavMesh(false)
	self.caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	self.caster:SetAutoUnstuck(false)
	self:StartIntervalThink(self.tick_rate)
	self:OnIntervalThink()
end

function modifier_leap_strike:OnIntervalThink()
	local elapsed = GameRules:GetGameTime() - self:GetCreationTime()
	local vertical_motion = Vector(0, 0, self.gravity)
	self.caster:AddPhysicsVelocity(vertical_motion)
	self.ticks = self.ticks + 1
end

function modifier_leap_strike:OnDestroy()
	if not IsServer() then return end
	self.caster:SetPhysicsVelocity(Vector(0, 0, 0))
	self.caster:FollowNavMesh(true)
	self.caster:SetNavCollisionType(PHYSICS_NAV_SLIDE)
	self.caster:SetAutoUnstuck(true)
	FindClearSpaceForUnit(self.caster, GetGroundPosition(self.caster:GetAbsOrigin(), self.caster), false)
	ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_ABSORIGIN, self.caster)
	self.caster:EmitSound("Hero_ElderTitan.EchoStomp")
	SimpleAOE({
		caster = self.caster,
		damage = self:GetAbility():GetAbilityDamage(),
		center = self.caster:GetAbsOrigin(),
		radius = self:GetAbility():GetSpecialValueFor("radius"),
		ability = self:GetAbility(),
		modifiers = {modifier_stunned = {duration = self:GetAbility():GetSpecialValueFor("stun_duration")}},
	})
end

function modifier_leap_strike:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end

function modifier_leap_strike:DeclareFunctions()
	return {MODIFIER_PROPERTY_DISABLE_TURNING}
end

function modifier_leap_strike:GetModifierDisableTurning()
	return 1
end