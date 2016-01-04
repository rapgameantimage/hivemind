drift = class({})

function drift:GetIntrinsicModifierName()
	return "modifier_drift"
end

---

LinkLuaModifier("modifier_drift", "heroes/kotl/drift", LUA_MODIFIER_MOTION_NONE)
modifier_drift = class({})

function modifier_drift:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE}
end

function modifier_drift:OnTakeDamage(info)
	if info.target == self:GetParent() then
		self:StartCooldown(self:GetCooldown(self:GetLevel()))
		self:GetParent():RemoveModifierByName("modifier_drift_buff")
	end
end

function modifier_drift:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.25)
end

function modifier_drift:OnIntervalThink()
	local ability = self:GetParent():GetPlayerOwner():GetAssignedHero():FindAbilityByName("summon_spirits")
	local distance = 0
	if ability and ability.center then
		distance = DistanceBetweenVectors(ability.center:GetAbsOrigin(), self:GetParent():GetAbsOrigin())
	end
	if self:GetAbility():IsCooldownReady() and distance > ability:GetSpecialValueFor("inner_radius") and distance < ability:GetSpecialValueFor("outer_radius") then
		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_drift_buff", {duration = 0.5})
	end
end

function modifier_drift:IsHidden()
	return true
end

---

LinkLuaModifier("modifier_drift_buff", "heroes/kotl/drift", LUA_MODIFIER_MOTION_NONE)
modifier_drift_buff = class({})

function modifier_drift_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE}
end

function modifier_drift_buff:GetModifierMoveSpeed_Absolute()
	return 650
end