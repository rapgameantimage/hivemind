bane_flicker = class({})
LinkLuaModifier("modifier_flicker", "heroes/bane/modifier_flicker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_flicker_invis", "heroes/bane/modifier_flicker_invis", LUA_MODIFIER_MOTION_NONE)

function bane_flicker:OnSpellStart()
	StartSoundEvent("Hero_Invoker.GhostWalk", self:GetCaster())
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_flicker", {duration = self:GetSpecialValueFor("duration")})
end

function bane_flicker:GetCastAnimation()
	return ACT_DOTA_IDLE
end