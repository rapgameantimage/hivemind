modifier_sticky_flame = class({})

function modifier_sticky_flame:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_sticky_flame:GetModifierMoveSpeedBonus_Percentage()
	return self.max_slow / 100 * self:GetStackCount() * -1
end

function modifier_sticky_flame:OnCreated()
	self.tick_rate = 0.5
	self.attacker = self:GetAbility():GetCaster()
	self.parent = self:GetParent()
	self.max_slow = self:GetAbility():GetSpecialValueFor("max_slow")
	self.max_dps = self:GetAbility():GetSpecialValueFor("max_dps")
	if IsServer() then
		self:StartIntervalThink(self.tick_rate)
	end
end

function modifier_sticky_flame:OnIntervalThink()
	ApplyDamage({
		attacker = self.attacker,
		victim = self.parent,
		damage = self.max_dps / 100 * self:GetStackCount() * self.tick_rate,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	})
end

function modifier_sticky_flame:GetEffectName()
	return "particles/heroes/phoenix/phoenix_sticky_flame_projectile.vpcf"
end

function modifier_sticky_flame:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end