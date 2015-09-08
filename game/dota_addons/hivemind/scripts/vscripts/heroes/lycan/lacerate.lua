lycan_lacerate = class({})
LinkLuaModifier("modifier_lacerate_intrinsic", "heroes/lycan/modifier_lacerate_intrinsic", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lacerate", "heroes/lycan/modifier_lacerate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lacerate_bleeding", "heroes/lycan/modifier_lacerate_bleeding", LUA_MODIFIER_MOTION_NONE)

function lycan_lacerate:GetIntrinsicModifierName()
	return "modifier_lacerate_intrinsic"
end