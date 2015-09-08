bane_soul_freeze = class({})
LinkLuaModifier("modifier_soul_freeze_passive", "heroes/bane/modifier_soul_freeze_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_soul_freeze", "heroes/bane/modifier_soul_freeze", LUA_MODIFIER_MOTION_NONE)

function bane_soul_freeze:GetIntrinsicModifierName()
	return "modifier_soul_freeze_passive"
end