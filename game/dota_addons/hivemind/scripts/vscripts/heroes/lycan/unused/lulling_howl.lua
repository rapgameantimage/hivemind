lycan_lulling_howl = class({})
LinkLuaModifier("modifier_howling", "heroes/lycan/modifier_howling", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_howl_timer", "heroes/lycan/modifier_howl_timer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_howl_counter", "heroes/lycan/modifier_howl_counter", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_howl_sleeping", "heroes/lycan/modifier_howl_sleeping", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_insomnia", "heroes/lycan/modifier_insomnia", LUA_MODIFIER_MOTION_NONE)

function lycan_lulling_howl:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_howling", {})
end

function lycan_lulling_howl:OnChannelFinish(interrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_howling")
end

function lycan_lulling_howl:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end