heavyweight = class({})

function heavyweight:OnSplitComplete()		-- This is not an actual event. It is invoked via callback in heroes/earth_spirit/split.lua
	SimpleAOE({
		caster = self:GetCaster(),
		center = self:GetCaster():GetAbsOrigin(),
		radius = self:GetSpecialValueFor("radius"),
		damage = self:GetAbilityDamage(),
		modifiers = { modifier_stunned = { duration = self:GetSpecialValueFor("stun_time") } },
		ability = self,
	})
	ParticleManager:CreateParticle("particles/heroes/earth_spirit/heavyweight.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
end

function heavyweight:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end