modifier_flicker_invis = class({})

function modifier_flicker_invis:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_flicker_invis:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK
	}	
end

function modifier_flicker_invis:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed_bonus")
end

function modifier_flicker_invis:OnAttack(params)
	if not IsServer() then return end

	if params.attacker == self:GetParent() then
		self:Destroy()
	end
end

function modifier_flicker_invis:IsPurgable()
	return true
end

function modifier_flicker_invis:IsHidden()
	return true
end