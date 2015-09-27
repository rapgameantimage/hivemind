modifier_firewall_burn = class({})

function modifier_firewall_burn:OnCreated()
	if not IsServer() then return end

	self.tick_rate = 0.25
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.dps = self.ability:GetSpecialValueFor("burn_dps")
	self.damage_per_tick = self.dps * self.tick_rate
	self.parent = self:GetParent()

	self:StartIntervalThink(self.tick_rate)
end

function modifier_firewall_burn:OnIntervalThink()
	ApplyDamage({
		attacker = self.caster,
		victim = self.parent,
		damage = self.damage_per_tick,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self.ability,
	})
end

function modifier_firewall_burn:GetEffectName()
	return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_firewall_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
