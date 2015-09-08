modifier_chilling_scream = class({})

function modifier_chilling_scream:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_chilling_scream:OnCreated()
	self.slow = self:GetAbility():GetSpecialValueFor("slow_percentage")
end

function modifier_chilling_scream:GetModifierMoveSpeedBonus_Percentage()
	return self.slow * -1
end

function modifier_chilling_scream:IsDebuff()
	return true
end

function modifier_chilling_scream:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_chilling_scream:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end