modifier_twilight_pulse_passive = class({})

function modifier_twilight_pulse_passive:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_twilight_pulse_passive:OnCreated()
	if not IsServer() then return end
	self.proc_chance = self:GetAbility():GetSpecialValueFor("proc_chance")
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.team = self.parent:GetTeam()
	self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_twilight_pulse_passive:OnAttackLanded(info)
	if not IsServer() then return end
	if info.attacker == self:GetParent() then
		if RandomInt(1,100) <= self.proc_chance then
			CreateModifierThinker(self.parent, self.ability, "modifier_twilight_pulse_thinker", {duration = self.duration}, info.target:GetAbsOrigin(), self.team, false)
		end
	end
end