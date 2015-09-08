modifier_forced_animation = class({})

function modifier_forced_animation:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
end

function modifier_forced_animation:GetOverrideAnimation()
	return ACT_DOTA_ATTACK
end

function modifier_forced_animation:GetOverrideAnimationRate()
	return 0.48
end

function modifier_forced_animation:IsHidden()
	return true
end