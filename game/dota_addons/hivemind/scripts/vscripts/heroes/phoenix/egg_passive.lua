egg_passive = class({})

function egg_passive:IsHidden()
	return true
end

function egg_passive:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end

function egg_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_LIFETIME_FRACTION}
end

function egg_passive:GetUnitLifetimeFraction()
	return ( ( self:GetDieTime() - GameRules:GetGameTime() ) / self:GetDuration() )
end

function egg_passive:OnDestroy()
	if not IsServer() then return end

	local ability = self:GetAbility()
	local caster = ability:GetCaster()
	local egg = self:GetParent()
	SimpleAOE({
		caster = caster,
		radius = ability:GetSpecialValueFor("explosion_radius"),
		ability = ability,
		center = egg:GetAbsOrigin(),
		damage = ability:GetSpecialValueFor("damage"),
		modifiers = {
			modifier_stunned = {duration = ability:GetSpecialValueFor("stun_time")}
		},
	})
	GridNav:DestroyTreesAroundPoint(egg:GetAbsOrigin(), ability:GetSpecialValueFor("explosion_radius"), false)
	ParticleManager:DestroyParticle(self.effects, false)
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf", PATTACH_ABSORIGIN_FOLLOW, egg)
	StartSoundEvent("Hero_Phoenix.SuperNova.Explode", egg)
	egg:ForceKill(false)
	egg:AddNoDraw()
end

function egg_passive:OnCreated()
	if not IsServer() then return end

	local egg = self:GetParent()
	self.effects = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_POINT_FOLLOW, egg)
	ParticleManager:SetParticleControlEnt(self.effects, 0, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(self.effects, 1, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
end