modifier_howling = class({})

function modifier_howling:IsAura()
	return true
end

function modifier_howling:GetModifierAura()
	return "modifier_howl_timer"
end

function modifier_howling:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_howling:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_howling:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_howling:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end
--[[
function modifier_howling:GetAuraEntityReject(entity)
	if entity:HasModifier("modifier_howl_sleeping") then
		return true
	else
		return false
	end
end
]]--