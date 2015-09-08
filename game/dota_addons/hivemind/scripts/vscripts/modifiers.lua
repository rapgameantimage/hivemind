modifier_hidden = class({})

function modifier_hidden:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
	return state
end

function modifier_hidden:IsHidden() -- lel
	return true
end

function modifier_hidden:OnCreated()
	if not IsServer() then return end
	self:GetParent():AddNoDraw()
end

function modifier_hidden:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveNoDraw()
end

-----

modifier_splitting = class({})

function modifier_splitting:GetEffectName()
	return "particles/split_target.vpcf"
end

function modifier_splitting:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_splitting:IsHidden()
	return true
end

-----

modifier_ok_to_complete_transformation = class({})

function modifier_ok_to_complete_transformation:IsHidden()
	return true
end

-----

modifier_postmortem_damage_source = class({})