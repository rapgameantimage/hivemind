modifier_berserk = class({})

function modifier_berserk:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_berserk:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("damage_bonus")
end

function modifier_berserk:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
end

function modifier_berserk:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true}
end

function modifier_berserk:OnCreated()
	if not IsServer() then return end
	self.particles = ParticleManager:CreateParticle("particles/heroes/lycan/berserk.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.particles, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
	self.particles2 = ParticleManager:CreateParticle("particles/heroes/lycan/berserk.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.particles2, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetParent():GetAbsOrigin(), true)
end

function modifier_berserk:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particles, false)
	ParticleManager:DestroyParticle(self.particles2, false)
end