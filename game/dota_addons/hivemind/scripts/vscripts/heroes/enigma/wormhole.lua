wormhole = class({})

function wormhole:OnSpellStart()
	GridNav:DestroyTreesAroundPoint(self:GetCursorPosition(), self:GetSpecialValueFor("radius"), false)
	CreateModifierThinker(self:GetCaster(), self, "modifier_wormhole_thinker", {duration = self:GetSpecialValueFor("duration")}, self:GetCursorPosition(), self:GetCaster():GetTeam(), false)
end

function wormhole:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function wormhole:GetCastAnimation()
	return ACT_DOTA_MIDNIGHT_PULSE
end

----------

LinkLuaModifier("modifier_wormhole_thinker", "heroes/enigma/wormhole", LUA_MODIFIER_MOTION_NONE)
modifier_wormhole_thinker = class({})

function modifier_wormhole_thinker:OnCreated()
	if not IsServer() then return end

	self.tick_rate = 0.25
	self.ability = self:GetAbility()
	self.pull_radius = self.ability:GetSpecialValueFor("radius")
	self.caster = self.ability:GetCaster()
	self.parent = self:GetParent()
	self.team = self.parent:GetTeam()
	self.origin = self.parent:GetAbsOrigin()
	self.max_distance = self.ability:GetSpecialValueFor("max_distance")
	self.min_distance = self.ability:GetSpecialValueFor("min_distance")

	self.particles = ParticleManager:CreateParticle("particles/heroes/enigma/wormhole.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.particles, 0, self.origin + Vector(0,0,128))
	StartSoundEvent("Hero_Enigma.BlackHole.Cast.Chasm", self.parent)

	self:StartIntervalThink(self.tick_rate)
	self:OnIntervalThink()
end

function modifier_wormhole_thinker:OnIntervalThink()
	local pull_units = FindUnitsInRadius(self.team, self.origin, nil, self.pull_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for k,unit in pairs(pull_units) do
		local origin = unit:GetAbsOrigin()
		local loc
		repeat
			loc = origin + RandomVector(RandomFloat(self.min_distance, self.max_distance))
		until GridNav:IsTraversable(loc)
		local startpart = ParticleManager:CreateParticle("particles/econ/events/ti5/blink_dagger_start_ti5.vpcf", PATTACH_WORLDORIGIN, unit)
		ParticleManager:SetParticleControl(startpart, 0, origin)
		FindClearSpaceForUnit(unit, loc, false)
		GridNav:DestroyTreesAroundPoint(loc, 300, false)
		local endpart = ParticleManager:CreateParticle("particles/econ/events/ti5/blink_dagger_end_ti5.vpcf", PATTACH_WORLDORIGIN, unit)
		ParticleManager:SetParticleControl(endpart, 0, loc)
		AddFOWViewer(self.team, loc, 700, 6, false)
	end
end

function modifier_wormhole_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particles, false)
	StopSoundEvent("Hero_Enigma.BlackHole.Cast.Chasm", self.parent)
end