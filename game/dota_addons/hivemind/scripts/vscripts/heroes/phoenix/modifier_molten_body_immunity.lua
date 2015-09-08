modifier_molten_body_immunity = class({})

function modifier_molten_body_immunity:IsHidden()
	return true
end

function modifier_molten_body_immunity:GetEffectName()
	return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_molten_body_immunity:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end