dimensional_bind = class({})
LinkLuaModifier("modifier_dimensional_bind", "heroes/enigma/dimensional_bind", LUA_MODIFIER_MOTION_NONE)

function dimensional_bind:OnSpellStart()
	local caster = self:GetCaster()
	local direction = ((self:GetCursorPosition() - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/econ/items/puck/puck_alliance_set/puck_illusory_orb_aproset.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = direction * self:GetSpecialValueFor("projectile_speed"),
		fDistance = self:GetSpecialValueFor("projectile_range"),
		fStartRadius = self:GetSpecialValueFor("projectile_radius"),
		fEndRadius = self:GetSpecialValueFor("projectile_radius"),
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	})
	StartSoundEvent("Hero_Enigma.Demonic_Conversion", caster)
end

function dimensional_bind:OnProjectileHit(target, loc)
	if target ~= nil then
		target:AddNewModifier(self:GetCaster(), self, "modifier_dimensional_bind", {duration = self:GetSpecialValueFor("duration")})
	end
end

modifier_dimensional_bind = class({})