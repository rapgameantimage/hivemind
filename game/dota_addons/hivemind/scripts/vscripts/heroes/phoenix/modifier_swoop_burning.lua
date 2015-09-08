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
