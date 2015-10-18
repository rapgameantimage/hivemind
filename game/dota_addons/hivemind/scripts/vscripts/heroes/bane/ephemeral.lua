ephemeral = class({})

function ephemeral:GetIntrinsicModifierName()
	return "modifier_ephemeral"
end

---

LinkLuaModifier("modifier_ephemeral", "heroes/bane/ephemeral", LUA_MODIFIER_MOTION_NONE)
modifier_ephemeral = class({})

function modifier_ephemeral:CheckState()
	return {[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_ephemeral:DeclareFunctions()
	return {MODIFIER_PROPERTY_EVASION_CONSTANT}
end

function modifier_ephemeral:GetModifierEvasion_Constant()
	return self:GetAbility():GetSpecialValueFor("evasion")
end