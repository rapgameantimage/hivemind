molten_body = class({})
LinkLuaModifier("modifier_molten_body", "heroes/phoenix/modifier_molten_body", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_molten_body_thinker", "heroes/phoenix/modifier_molten_body_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_molten_body_immunity", "heroes/phoenix/modifier_molten_body_immunity", LUA_MODIFIER_MOTION_NONE)

function molten_body:GetIntrinsicModifierName()
	return "modifier_molten_body"
end
