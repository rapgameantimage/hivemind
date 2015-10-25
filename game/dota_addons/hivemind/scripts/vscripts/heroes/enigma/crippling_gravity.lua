crippling_gravity = class({})

function crippling_gravity:OnSpellStart()
	self:GetCursorTarget():AddNewModifier(self:GetCaster(), self, "modifier_crippling_gravity", {duration = self:GetSpecialValueFor("duration")})
	StartSoundEvent("DOTA_Item.RodOfAtos.Activate", self:GetCaster())
	ParticleManager:CreateParticle("particles/items2_fx/rod_of_atos_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCursorTarget())
end

function crippling_gravity:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

------

modifier_crippling_gravity = class({})
LinkLuaModifier("modifier_crippling_gravity", "heroes/enigma/crippling_gravity", LUA_MODIFIER_MOTION_NONE)

function modifier_crippling_gravity:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_crippling_gravity:GetModifierMoveSpeedBonus_Percentage()
	return ( -100 * self:GetRemainingTime() ) / self:GetDuration()
end

function modifier_crippling_gravity:GetModifierAttackSpeedBonus_Constant()
	return ( -100 * self:GetRemainingTime() ) / self:GetDuration()
end

function modifier_crippling_gravity:GetEffectName()
	return "particles/items2_fx/rod_of_atos_debuff.vpcf"
end

function modifier_crippling_gravity:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_crippling_gravity:IsPurgable()
	return true
end

function modifier_crippling_gravity:IsDebuff()
	return true 
end