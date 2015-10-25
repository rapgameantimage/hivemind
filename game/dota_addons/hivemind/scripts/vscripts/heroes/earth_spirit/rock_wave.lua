rock_wave = class({})

function rock_wave:OnAbilityPhaseStart()
	StartSoundEvent("Hero_EarthSpirit.RollingBoulder.Cast", self:GetCaster())
	return true
end

function rock_wave:OnSpellStart()
	local caster = self:GetCaster()
	self.direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	self.ticks = 0
	self.max_ticks = math.floor(1 / 0.03)
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/nothing.vpcf",
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = self.direction * 1200,
		fDistance = 1200,
		fStartRadius = 75,
		fEndRadius = 150,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = false,
		bProvidesVision = true,
		bObstructedVision = true,
		iVisionRadius = 600,
		iVisionTeamNumber = caster:GetTeam(),
	})
	StartSoundEvent("Hero_EarthSpirit.RollingBoulder.Loop", caster)
	--StartSoundEvent("Hero_EarthSpirit.RollingBoulder.Destroy", caster)
end

function rock_wave:OnProjectileHit(target, loc)
	if target then
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			damage = self:GetSpecialValueFor("min_damage") + ((self:GetSpecialValueFor("max_damage") - self:GetSpecialValueFor("min_damage")) * self.ticks / self.max_ticks),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self,
		})
		local stun_time = self:GetSpecialValueFor("min_stun") + ((self:GetSpecialValueFor("max_stun") - self:GetSpecialValueFor("min_stun")) * self.ticks / self.max_ticks)
		target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = stun_time})
		target:AddNewModifier(self:GetCaster(), self, "modifier_rock_wave_lift", {duration = stun_time * 0.75})
		target:EmitSound("Hero_EarthSpirit.RollingBoulder.Target")
	else
		StopSoundEvent("Hero_EarthSpirit.RollingBoulder.Loop", self:GetCaster())
		StartSoundEventFromPosition("Hero_EarthSpirit.RollingBoulder.Destroy", loc)
		AddFOWViewer(self:GetCaster():GetTeam(), loc, 600, 1, true)
	end
end

function rock_wave:OnProjectileThink(loc)
	self.ticks = self.ticks + 1
	local p = ParticleManager:CreateParticle("particles/heroes/earth_spirit/rock_wave1.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(p, 0, GetGroundPosition(loc, nil) + self.direction * 64 - Vector(0, 0, 75))
	ParticleManager:SetParticleControl(p, 1, Vector(self.ticks, 0, 0))
	if self.ticks % 2 == 1 then
		local p2 = ParticleManager:CreateParticle("particles/heroes/earth_spirit/rock_wave_soil.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(p2, 0, GetGroundPosition(loc, nil))
		ParticleManager:SetParticleControl(p2, 1, self.direction)
		ParticleManager:SetParticleControl(p2, 2, Vector(self.ticks, 0, 0))
	end
	CreateModifierThinker(self:GetCaster(), self, "modifier_rock_wave_blocker", {duration = 0.4}, loc, self:GetCaster():GetTeam(), true)
	GridNav:DestroyTreesAroundPoint(loc, 64, true)
end

function rock_wave:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

---

LinkLuaModifier("modifier_rock_wave_lift", "heroes/earth_spirit/rock_wave", LUA_MODIFIER_MOTION_NONE)
modifier_rock_wave_lift = class({})

function modifier_rock_wave_lift:OnCreated()
	if not IsServer() then return end
	self.lift = 2400 * self:GetDuration()
	self.gravity = self.lift * -2
	self.tick_rate = 0.03
	self.ticks = 0
	self.total_ticks = math.floor(self:GetDuration() / self.tick_rate)

	self.parent = self:GetParent()
	self:StartIntervalThink(self.tick_rate)
end

function modifier_rock_wave_lift:OnIntervalThink()
	local origin = self.parent:GetAbsOrigin()
	local z_motion = self.lift * self.tick_rate		-- Lift
	z_motion = z_motion + self.gravity * self.tick_rate * (self.ticks / self.total_ticks)	-- Gravity
	local desired_origin = origin + Vector(0, 0, z_motion)
	if desired_origin.z < GetGroundHeight(desired_origin, self.parent) then
		desired_origin.z = GetGroundHeight(desired_origin, self.parent)
	end
	self.parent:SetAbsOrigin(desired_origin)
	self.ticks = self.ticks + 1
end

function modifier_rock_wave_lift:OnDestroy()
	if not IsServer() then return end
	self.parent:SetAbsOrigin(GetGroundPosition(self.parent:GetAbsOrigin(), self.parent))
end

function modifier_rock_wave_lift:IsHidden()
	return true
end

---

LinkLuaModifier("modifier_rock_wave_blocker", "heroes/earth_spirit/rock_wave", LUA_MODIFIER_MOTION_NONE)
modifier_rock_wave_blocker = class({})