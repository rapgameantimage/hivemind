lycan_berserk = class({})
LinkLuaModifier("modifier_berserk", "heroes/lycan/modifier_berserk", LUA_MODIFIER_MOTION_NONE)

function lycan_berserk:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_berserk", {duration = self:GetSpecialValueFor("duration")})
	--ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_rage_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	StartSoundEvent("Hero_Lycan.Shapeshift.Cast", caster)
end