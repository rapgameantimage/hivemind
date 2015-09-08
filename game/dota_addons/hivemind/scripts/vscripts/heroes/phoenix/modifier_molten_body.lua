modifier_molten_body = class({})

function modifier_molten_body:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_molten_body:OnAttackLanded(info)
	local ability = self:GetAbility()
	if info.target == self:GetParent() and ability:IsCooldownReady() then
		if RandomInt(1, 100) <= ability:GetSpecialValueFor("proc_chance") then
			CreateModifierThinker(self:GetParent(), ability, "modifier_molten_body_thinker", {duration = ability:GetSpecialValueFor("duration")}, self:GetParent():GetAbsOrigin(), self:GetParent():GetTeam(), false)
			ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
		end
	end
end

function modifier_molten_body:IsHidden()
	return true
end