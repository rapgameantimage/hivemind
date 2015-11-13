unearthly_roar = class({})

function unearthly_roar:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function unearthly_roar:OnSpellStart()
	local caster = self:GetCaster()
	SimpleAOE({
		ability = self,
		caster = caster,
		center = self:GetCursorPosition(),
		radius = self:GetSpecialValueFor("radius"),
		modifiers = {
			modifier_unearthly_roar = { duration = self:GetSpecialValueFor("duration") },
		},
	})
	caster:EmitSound("n_creep_Thunderlizard_Big.Roar")
	local p = ParticleManager:CreateParticle("particles/heroes/shadow_demon/unearthly_roar.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(p, 0, self:GetCursorPosition())
	ParticleManager:SetParticleControl(p, 1, Vector(self:GetSpecialValueFor("radius"), 1, 1))
end

---

LinkLuaModifier("modifier_unearthly_roar", "heroes/shadow_demon/unearthly_roar", LUA_MODIFIER_MOTION_NONE)
modifier_unearthly_roar = class({})

function modifier_unearthly_roar:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.03)
end

function modifier_unearthly_roar:OnIntervalThink()
	local curses = {"modifier_confusion", "modifier_aeonic_curse", "modifier_spectral_curse"}
	for k,name in pairs(curses) do
		if self:GetParent():HasModifier(name) then
			local mod = self:GetParent():FindModifierByName(name)
			mod:SetDuration(mod:GetRemainingTime() + 0.03, true)
			print(mod:GetDuration())
		end
	end
end