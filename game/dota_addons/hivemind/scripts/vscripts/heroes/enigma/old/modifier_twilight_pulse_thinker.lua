modifier_twilight_pulse_thinker = class({})

function modifier_twilight_pulse_thinker:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.hp_drain = self.ability:GetSpecialValueFor("hp_drain")
	self.caster = self.ability:GetCaster()
	self.team = self.caster:GetTeam()
	self.parent = self:GetParent()
	self.center = self.parent:GetAbsOrigin()
	self.tick_rate = 1

	self.particles = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.particles, 1, Vector(self.radius, 0, 0)) -- sets size of particle
	StartSoundEvent("Hero_Enigma.Midnight_Pulse", self.parent)

	self:StartIntervalThink(self.tick_rate)
end

function modifier_twilight_pulse_thinker:OnIntervalThink()
	local units = FindUnitsInRadius(self.team, self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for k,unit in pairs(units) do
		if not unit:HasModifier("modifier_twilight_pulse_immunity") then
			ApplyDamage({
				victim = unit,
				attacker = self.caster,
				ability = self,
				damage_type = DAMAGE_TYPE_MAGICAL,
				damage = unit:GetMaxHealth() * self.hp_drain / 100 * self.tick_rate,
			})
			unit:AddNewModifier(self.caster, self.ability, "modifier_twilight_pulse_immunity", { duration = self.tick_rate - 0.03 })
		end
	end
end

function modifier_twilight_pulse_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particles, false)
end

modifier_twilight_pulse_immunity = class({})

function modifier_twilight_pulse_immunity:IsHidden()
	return true
end