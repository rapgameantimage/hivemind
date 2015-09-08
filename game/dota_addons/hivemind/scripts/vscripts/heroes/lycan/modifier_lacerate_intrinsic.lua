modifier_lacerate_intrinsic = class({})

function modifier_lacerate_intrinsic:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_lacerate_intrinsic:OnAttackLanded(info)
	if not IsServer() then return end
	if self:GetParent():PassivesDisabled() then return end

	if info.attacker == self:GetParent() then
		info.target:AddNewModifier(info.attacker, self:GetAbility(), "modifier_lacerate", {})
	end
end

function modifier_lacerate_intrinsic:IsHidden()
	return true
end