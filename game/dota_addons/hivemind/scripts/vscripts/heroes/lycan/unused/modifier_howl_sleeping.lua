modifier_howl_sleeping = class({})

function modifier_howl_sleeping:CheckState()
	return {
		[MODIFIER_STATE_NIGHTMARED] = true
	}
end

function modifier_howl_sleeping:GetEffectName()
	return "particles/generic_gameplay/generic_sleep.vpcf"
end

function modifier_howl_sleeping:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_howl_sleeping:OnDestroy()
	self:GetParent():AddNewModifier(self:GetAbility():GetCaster(), self:GetAbility(), "modifier_insomnia", {duration = self:GetAbility():GetSpecialValueFor("insomnia_duration")})
end