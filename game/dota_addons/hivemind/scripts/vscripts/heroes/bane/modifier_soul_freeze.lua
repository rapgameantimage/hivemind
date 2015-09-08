modifier_soul_freeze = class({})

function modifier_soul_freeze:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	if self.parent:IsConsideredHero() then
		self.slow_per_stack = self.ability:GetSpecialValueFor("slow_per_stack_hero")
	else
		self.slow_per_stack = self.ability:GetSpecialValueFor("slow_per_stack_non_hero")
	end
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
		ParticleManager:SetParticleControl(self.particles, 1, Vector(stacks, 0, 0))
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