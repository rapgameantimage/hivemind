bane_chilling_scream = class({})
LinkLuaModifier("modifier_chilling_scream", "heroes/bane/modifier_chilling_scream", LUA_MODIFIER_MOTION_NONE)

function bane_chilling_scream:OnAbilityPhaseStart()
	-- Stupid workaround for ACT_DOTA_ATTACK not playing properly when interrupting a normal attack.
	StartAnimation(self:GetCaster(), {duration = 1, activity = ACT_DOTA_ATTACK, rate = 1})
	return true
end

function bane_chilling_scream:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

function bane_chilling_scream:OnSpellStart()
	local caster = self:GetCaster()
	local direction = ((self:GetCursorPosition() - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	local projectile = ({
		Ability = self,
		EffectName = "particles/heroes/bane/chilling_scream.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = direction * self:GetSpecialValueFor("projectile_speed"),
		fDistance = self:GetSpecialValueFor("projectile_distance"),
		fStartRadius = self:GetSpecialValueFor("projectile_radius_start"),
		fEndRadius = self:GetSpecialValueFor("projectile_radius_end"),
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	})
	ProjectileManager:CreateLinearProjectile(projectile)
	StartSoundEvent("Hero_QueenOfPain.ScreamOfPain", caster)
end

function bane_chilling_scream:OnProjectileHit(target, loc)
	if target ~= nil then
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			damage = self:GetAbilityDamage(),
			damage_type = self:GetAbilityDamageType(),
			ability = self,
		})
		target:AddNewModifier(self:GetCaster(), self, "modifier_chilling_scream", {duration = self:GetSpecialValueFor("slow_duration")})
	end
end