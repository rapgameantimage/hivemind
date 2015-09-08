dissolution = class({})
LinkLuaModifier("modifier_dissolution", "heroes/phoenix/dissolution", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_molten_body_thinker", "heroes/phoenix/modifier_molten_body_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_molten_body_immunity", "heroes/phoenix/modifier_molten_body_immunity", LUA_MODIFIER_MOTION_NONE)

function dissolution:GetIntrinsicModifierName()
	return "modifier_dissolution"
end

-------

modifier_dissolution = class({})

function modifier_dissolution:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_dissolution:OnDeath(info)
	if info.unit == self:GetParent() then
		CreateModifierThinker(self:GetParent(), self:GetAbility(), "modifier_molten_body_thinker", {duration = self:GetAbility():GetSpecialValueFor("duration")}, self:GetParent():GetAbsOrigin(), self:GetParent():GetTeam(), false)
	end
end

function modifier_dissolution:IsHidden()
	return true
end