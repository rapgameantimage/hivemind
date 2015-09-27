wraithpyre = class({})

function wraithpyre:OnToggle()
	if self:GetToggleState() == true then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_wraithpyre", {})
	else
		self:GetCaster():RemoveModifierByName("modifier_wraithpyre")
	end
end

function wraithpyre:GetAOERadius()
	return 200
end

---

LinkLuaModifier("modifier_wraithpyre", "heroes/wraith/wraithpyre", LUA_MODIFIER_MOTION_NONE)
modifier_wraithpyre = class({})

function modifier_wraithpyre:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.parent = self:GetParent()
		self.mana_per_second = self.ability:GetSpecialValueFor("mana_per_second")
		self.radius = self.ability:GetSpecialValueFor("radius")
		self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
		self:StartIntervalThink(1)
	end
end

function modifier_wraithpyre:OnIntervalThink()
	-- Spend mana cost, or deactivate if we don't have it
	if self.parent:GetMana() > self.mana_per_second then
		self.parent:SpendMana(self.mana_per_second, self.ability)
	else
		self.ability:ToggleAbility()
	end

	-- Add a stack of the modifier to nearby units
	SimpleAOE({
		radius = self.radius,
		ability = self.ability,
		caster = self.parent,
		center = self.parent:GetAbsOrigin(),
		modifiers = {
			modifier_wraithpyre_debuff = {duration = self.debuff_duration}
		}
	})
end

function modifier_wraithpyre:GetEffectName()
	return "particles/heroes/wraith/wraithpyre.vpcf"
end

function modifier_wraithpyre:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---

LinkLuaModifier("modifier_wraithpyre_debuff", "heroes/wraith/wraithpyre", LUA_MODIFIER_MOTION_NONE)
modifier_wraithpyre_debuff = class({})

function modifier_wraithpyre_debuff:OnCreated()
	self.ability = self:GetAbility()
	self.minus_armor_per_stack = self.ability:GetSpecialValueFor("minus_armor_per_stack")
	self.minus_magic_resist_per_stack = self.ability:GetSpecialValueFor("minus_magic_resist_per_stack")
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	if IsServer() then
		self:SetStackCount(1)
	end
end

function modifier_wraithpyre_debuff:OnRefresh()
	if IsServer() then
		if self:GetStackCount() < self.max_stacks then
			self:SetStackCount(self:GetStackCount() + 1)
		end
	end
end

function modifier_wraithpyre_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_wraithpyre_debuff:GetModifierPhysicalArmorBonus()
	return self:GetStackCount() * self.minus_armor_per_stack * -1
end

function modifier_wraithpyre_debuff:GetModifierMagicalResistanceBonus()
	return self:GetStackCount() * self.minus_magic_resist_per_stack * -1
end