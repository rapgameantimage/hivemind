creeping_shadows = class({})

function creeping_shadows:GetIntrinsicModifierName()
	return "modifier_creeping_shadows_passive"
end

---

LinkLuaModifier("modifier_creeping_shadows_passive", "heroes/shadow_demon/creeping_shadows", LUA_MODIFIER_MOTION_NONE)
modifier_creeping_shadows_passive = class({})

function modifier_creeping_shadows_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_creeping_shadows_passive:OnAttackLanded(event)
	if event.attacker == self:GetParent() and not self:GetParent():PassivesDisabled() and not event.target:IsMagicImmune() then
		event.target:AddNewModifier(event.attacker, self:GetAbility(), "modifier_creeping_shadows_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration")})
	end
end

function modifier_creeping_shadows_passive:IsHidden()
	return true
end

---

LinkLuaModifier("modifier_creeping_shadows_debuff", "heroes/shadow_demon/creeping_shadows", LUA_MODIFIER_MOTION_NONE)
modifier_creeping_shadows_debuff = class({})

function modifier_creeping_shadows_debuff:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(1)
	--self.particle = ParticleManager:CreateParticle("particles/heroes/shadow_demon/creeping_shadows.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_creeping_shadows_debuff:OnRefresh()
	if self:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
		self:IncrementStackCount()
		if IsServer() then
			--ParticleManager:SetParticleControl(self.particle, 1, Vector(self:GetStackCount(), 0, 0))
		end
	end
end

function modifier_creeping_shadows_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_creeping_shadows_debuff:GetModifierMiss_Percentage()
	return self:GetAbility():GetSpecialValueFor("miss_chance_per_stack") * self:GetStackCount()
end

function modifier_creeping_shadows_debuff:IsDebuff()
	return true
end

function modifier_creeping_shadows_debuff:IsPurgable()
	return true
end

function modifier_creeping_shadows_debuff:OnDestroy()
	if not IsServer() then return end
	--ParticleManager:DestroyParticle(self.particle, false)
end