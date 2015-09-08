modifier_sticky_flame_projectile = class({})

function modifier_sticky_flame_projectile:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_sticky_flame_projectile:GetEffectName()
	return "particles/heroes/phoenix/phoenix_sticky_flame_projectile.vpcf"
end

function modifier_sticky_flame_projectile:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
