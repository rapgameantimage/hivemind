lycan_echoing_howl = class({})
LinkLuaModifier("modifier_howling", "heroes/lycan/modifier_howling", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_howling_slow", "heroes/lycan/modifier_howling_slow", LUA_MODIFIER_MOTION_NONE)

function lycan_echoing_howl:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_howling", {duration = self:GetSpecialValueFor("duration")})
	StartSoundEvent("Hero_Lycan.Howl", caster)
	ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function lycan_echoing_howl:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end