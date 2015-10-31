smite = class({})

function smite:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	CreateModifierThinker(caster, self, "modifier_smite_thinker", {duration = self:GetSpecialValueFor("delay")}, target, caster:GetTeam(), false)
	self.guiding_particle = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_invoker/invoker_sun_strike_team.vpcf", PATTACH_WORLDORIGIN, nil, caster:GetTeam())
	ParticleManager:SetParticleControl(self.guiding_particle, 0, target)
	ParticleManager:SetParticleControl(self.guiding_particle, 1, Vector(50, 0, 0))	-- size
	EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "Hero_Luna.LucentBeam.Cast", caster)
end

function smite:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

---

LinkLuaModifier("modifier_smite_thinker", "heroes/omniknight/smite", LUA_MODIFIER_MOTION_NONE)
modifier_smite_thinker = class({})

function modifier_smite_thinker:OnDestroy()
	if not IsServer() then return end
	local p = ParticleManager:CreateParticle("particles/econ/items/luna/luna_lucent_ti5_gold/luna_eclipse_impact_notarget_moonfall_gold.vpcf", PATTACH_WORLDORIGIN, nil)
	local cps = {0, 1, 2, 5, 6}
	for k,cp in pairs(cps) do
		ParticleManager:SetParticleControl(p, cp, self:GetParent():GetAbsOrigin())
	end
	local ability = self:GetAbility()
	SimpleAOE({
		caster = ability:GetCaster(),
		radius = ability:GetSpecialValueFor("radius"),
		ability = ability,
		damage = ability:GetAbilityDamage(),
		center = self:GetParent():GetAbsOrigin(),
	})
	ParticleManager:DestroyParticle(self:GetAbility().guiding_particle,true)
	self:GetParent():EmitSound("Hero_Luna.LucentBeam.Target")
end