razor_leaves = class({})

function razor_leaves:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_razor_leaves", {duration = self:GetSpecialValueFor("duration")})
end

function razor_leaves:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

---

LinkLuaModifier("modifier_razor_leaves", "heroes/treant/razor_leaves", LUA_MODIFIER_MOTION_NONE)
modifier_razor_leaves = class({})

function modifier_razor_leaves:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_razor_leaves:OnIntervalThink()
	SimpleAOE({
		caster = self:GetParent(),
		center = self:GetParent():GetAbsOrigin(),
		ability = self:GetAbility(),
		damage = self:GetAbility():GetSpecialValueFor("storm_dps"),
		radius = self:GetAbility():GetSpecialValueFor("radius"),
		modifiers = {
			modifier_razor_leaves_bleed = {duration = self:GetAbility():GetSpecialValueFor("bleed_duration")}
		},
	})
end

function modifier_razor_leaves:GetEffectName()
	return "particles/heroes/treant/razor_leaves.vpcf"
end

function modifier_razor_leaves:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---

LinkLuaModifier("modifier_razor_leaves_bleed", "heroes/treant/razor_leaves", LUA_MODIFIER_MOTION_NONE)
modifier_razor_leaves_bleed = class({})

function modifier_razor_leaves_bleed:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_razor_leaves_bleed:OnIntervalThink()
	ApplyDamage({
		attacker = self:GetAbility():GetCaster(),
		victim = self:GetParent(),
		damage = self:GetAbility():GetSpecialValueFor("bleed_dps"),
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility()
	})
end

function modifier_razor_leaves_bleed:GetEffectName()
	return "particles/items2_fx/sange_maim.vpcf"
end

function modifier_razor_leaves_bleed:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end