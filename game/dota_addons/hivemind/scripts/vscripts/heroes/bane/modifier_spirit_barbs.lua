modifier_spirit_barbs = class({})

function modifier_spirit_barbs:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_spirit_barbs:OnTakeDamage(info)
	if IsServer() then 
		self:GetParent():ReduceMana(info.damage * self:GetAbility():GetSpecialValueFor("multiplier"))
	end
end

function modifier_spirit_barbs:GetEffectName()
	return "particles/units/heroes/hero_bane/bane_enfeeble.vpcf"
end

function modifier_spirit_barbs:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end