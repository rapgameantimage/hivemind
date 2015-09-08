fiery_birth = class({})
LinkLuaModifier("egg_passive", "heroes/phoenix/egg_passive", LUA_MODIFIER_MOTION_NONE)

function fiery_birth:OnSpellStart()
	self.caster = self:GetCaster()
	self.egg = CreateUnitByName("npc_dota_fiery_birth_egg", self.caster:GetAbsOrigin(), true, self.caster, self.caster, self.caster:GetTeam())
	self.egg:AddNewModifier(self.caster, self, "egg_passive", {duration = self:GetSpecialValueFor("delay")})
	self.egg:StartGesture(ACT_DOTA_CAPTURE)
	StartSoundEvent("Hero_Phoenix.SuperNova.Begin", self.caster)
	GridNav:DestroyTreesAroundPoint(self.egg:GetAbsOrigin(), self:GetSpecialValueFor("radius"), false)
end

function fiery_birth:GetCastAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_2
end