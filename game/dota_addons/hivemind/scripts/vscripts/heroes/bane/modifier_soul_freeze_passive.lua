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
			info.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_soul_freeze", {})
		end
	end
end