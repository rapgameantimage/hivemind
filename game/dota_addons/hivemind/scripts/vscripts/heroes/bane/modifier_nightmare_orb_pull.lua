modifier_nightmare_orb_pull = class({})

function modifier_nightmare_orb_pull:OnCreated()
	if not IsServer() then return end
	self:GetParent():Stop()
	ExecuteOrderFromTable({
		UnitIndex = self:GetParent():GetEntityIndex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = self:GetCaster():GetEntityIndex(),
	})
	self:GetParent():SetForceAttackTarget(self:GetCaster())
end

function modifier_nightmare_orb_pull:OnDestroy()
	if not IsServer() then return end
	self:GetParent():SetForceAttackTarget(nil)
end

function modifier_nightmare_orb_pull:GetEffectName()
	return "particles/heroes/bane/nightmare_orb_status.vpcf"
end

function modifier_nightmare_orb_pull:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end