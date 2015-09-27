bane_soul_freeze = class({})

function bane_soul_freeze:GetIntrinsicModifierName()
	return "modifier_soul_freeze_passive"
end

---

LinkLuaModifier("modifier_soul_freeze_passive", "heroes/bane/soul_freeze", LUA_MODIFIER_MOTION_NONE)
modifier_soul_freeze_passive = class({})

function modifier_soul_freeze_passive:IsHidden()
	return true
end

function modifier_soul_freeze_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_soul_freeze_passive:OnAttackLanded(info)
	if IsServer() then
		if info.attacker == self:GetParent() then
			info.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_soul_freeze", {duration = self:GetAbility():GetSpecialValueFor("duration")})
		end
	end
end

---

LinkLuaModifier("modifier_soul_freeze", "heroes/bane/soul_freeze", LUA_MODIFIER_MOTION_NONE)
modifier_soul_freeze = class({})

function modifier_soul_freeze:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	self.slow_per_stack = self.ability:GetSpecialValueFor("slow_per_stack")
	self:SetStackCount(1)

	if not IsServer() then return end

	self.particles = ParticleManager:CreateParticle("particles/heroes/bane/soul_freeze.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.particles, 1, Vector(1, 0, 0))
end

function modifier_soul_freeze:OnRefresh()
	if not IsServer() then return end
	local stacks = self:GetStackCount()
	if stacks < self.max_stacks then
		self:IncrementStackCount()
		ParticleManager:SetParticleControl(self.particles, 1, Vector(stacks * 2, 0, 0))
	end
end

function modifier_soul_freeze:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.particles, true)
	end
end

function modifier_soul_freeze:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT}
end

function modifier_soul_freeze:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount() * self.slow_per_stack * -1
end