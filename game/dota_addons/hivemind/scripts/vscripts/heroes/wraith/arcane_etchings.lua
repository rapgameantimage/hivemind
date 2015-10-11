arcane_etchings = class({})

function arcane_etchings:GetIntrinsicModifierName()
	return "modifier_arcane_etchings"
end

---

LinkLuaModifier("modifier_arcane_etchings", "heroes/wraith/arcane_etchings", LUA_MODIFIER_MOTION_NONE)
modifier_arcane_etchings = class({})

function modifier_arcane_etchings:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_arcane_etchings:OnCreated()
	self.magic_resist = self:GetAbility():GetSpecialValueFor("magic_resist")
end

function modifier_arcane_etchings:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end