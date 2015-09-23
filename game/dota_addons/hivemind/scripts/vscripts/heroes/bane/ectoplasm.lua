ectoplasm = class({})

function ectoplasm:OnSpellStart()
	-- Settings for projectile
	local projectile_radius = 150	 -- Also change in OnProjectileHit
	local projectile_speed = 800
	local projectile_range = 900

	local caster = self:GetCaster()
	caster:EmitSound("Hero_Venomancer.VenomousGale")
	local direction = ((self:GetCursorPosition() - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	self.projectile = ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/heroes/bane/ectoplasm.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin() + (direction * 50) + Vector(0, 0, 128),
		vVelocity = direction * projectile_speed,
		fDistance = projectile_range,
		fStartRadius = projectile_radius,
		fEndRadius = projectile_radius,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
	})
end

function ectoplasm:OnProjectileHit(target, loc)
	local aoe = {
		caster = self:GetCaster(),
		center = loc,
		radius = 150,
		ability = self,
		modifiers = {
			modifier_ectoplasm = {duration = self:GetSpecialValueFor("duration")},
		},
	}
	EmitSoundOnLocationWithCaster(loc, "Hero_Venomancer.VenomousGaleImpact", self:GetCaster())
	SimpleAOE(aoe)
	-- if the projectile is created and then immediately destroyed, the particle will appear at the origin instead of where it's supposed to...
	Timers:CreateTimer(0.03, function()
		ProjectileManager:DestroyLinearProjectile(self.projectile)
	end)
end

function ectoplasm:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

---

LinkLuaModifier("modifier_ectoplasm", "heroes/bane/ectoplasm", LUA_MODIFIER_MOTION_NONE)
modifier_ectoplasm = class({})

function modifier_ectoplasm:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ectoplasm:GetModifierTurnRate_Percentage()
	return self:GetStackCount() * -1
end

function modifier_ectoplasm:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * -1
end

function modifier_ectoplasm:OnCreated()
	-- settings
	self.distance_per_stack = 40
	self.angle_per_stack = 25
	self.max_stacks = self:GetAbility():GetSpecialValueFor("max_slow")

	-- initialization
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.particles = ParticleManager:CreateParticle("particles/heroes/bane/ectoplasm_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	self.forward_vector = self.parent:GetForwardVector()
	self.origin = self.parent:GetAbsOrigin()
	self.total_turning, self.total_movement = 0, 0
	self:SetStackCount(0)
	self:StartIntervalThink(0.09)
	self:OnIntervalThink()
end

-- watch how much the victim has turned or moved, and set the stack count based on that.
function modifier_ectoplasm:OnIntervalThink()
	-- Compare our forward vector to what it was the last time we checked, then increment our total turning accordingly
	local new_forward_vector = self.parent:GetForwardVector()
	local forward_diff = math.abs(RotationDelta(VectorToAngles(self.forward_vector), VectorToAngles(new_forward_vector)).y)
	self.total_turning = self.total_turning + forward_diff
	self.forward_vector = new_forward_vector

	-- Compare our position to what it was the last time we checked, then increment our total movement accordingly
	local new_origin = self.parent:GetAbsOrigin()
	local origin_diff = DistanceBetweenVectors(self.origin, new_origin)
	self.total_movement = self.total_movement + origin_diff
	self.origin = new_origin

	-- Update our stack count based on how much we've turned and moved
	local new_stack_count = (self.total_turning / self.angle_per_stack) + (self.total_movement / self.distance_per_stack)
	if new_stack_count > self.max_stacks then
		new_stack_count = self.max_stacks
	end
	self:SetStackCount(new_stack_count)
	ParticleManager:SetParticleControl(self.particles, 1, Vector(new_stack_count, 0, 0)) -- scale sprites
	ParticleManager:SetParticleControl(self.particles, 2, Vector(1 + new_stack_count / 10, 1 + new_stack_count / 10, 1 + new_stack_count / 10)) -- scale blobs
end

function modifier_ectoplasm:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particles, false)
	ParticleManager:ReleaseParticleIndex(self.particles)
end