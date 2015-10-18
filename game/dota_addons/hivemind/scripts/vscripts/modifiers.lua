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

function modifier_hidden:IsHidden() -- lol
	return true
end

function modifier_hidden:OnCreated()
	if not IsServer() then return end
	-- Hide models
	self:GetParent():AddNoDraw()

	-- Hide the unit underground so that we don't have to worry about hiding their particles. (Idea stolen from SpellLibrary)
	self:GetParent():SetAbsOrigin(self:GetParent():GetAbsOrigin() + Vector(0, 0, -300))
end

function modifier_hidden:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveNoDraw()
	-- No need to return them to the surface, they'll get moved back when they transform anyway.
end

function modifier_hidden:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BONUS_DAY_VISION,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
	}
end

function modifier_hidden:GetBonusDayVision()
	return -9999
end

function modifier_hidden:GetBonusNightVision()
	return -9999
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

-----

modifier_waiting_for_new_round = class({})

function modifier_waiting_for_new_round:IsHidden()
	return true
end

function modifier_waiting_for_new_round:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_waiting_for_new_round:GetOverrideAnimation()
	return ACT_DOTA_VICTORY
end

function modifier_waiting_for_new_round:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_COMMAND_RESTRICTED] = true,}
end

---

modifier_nonexistent = class({})

function modifier_nonexistent:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_nonexistent:IsHidden()
	return true
end

function modifier_nonexistent:OnCreated()
	if not IsServer() then return end
	self:GetParent():AddNoDraw()
end