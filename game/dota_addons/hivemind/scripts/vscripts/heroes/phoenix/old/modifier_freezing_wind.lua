modifier_freezing_wind = class({})

function modifier_freezing_wind:OnCreated()
	self.slow = self:GetAbility():GetSpecialValueFor("slow_percentage")
end

function modifier_freezing_wind:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_freezing_wind:GetModifierMoveSpeedBonus_Percentage()
	return self.slow * -1
end

function modifier_freezing_wind:GetEffectName()
	return "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast_slow.vpcf"
end

function modifier_freezing_wind:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end