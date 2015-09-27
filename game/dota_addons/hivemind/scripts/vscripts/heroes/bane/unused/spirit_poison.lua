bane_spirit_poison = class({})

function bane_spirit_poison:OnSpellStart()
	local caster = self:GetCaster()
	local direction = ((self:GetCursorPosition() - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_projectile.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = direction * self:GetSpecialValueFor("projectile_speed"),
		fDistance = self:GetSpecialValueFor("projectile_range"),
		fStartRadius = self:GetSpecialValueFor("projectile_radius"),
		fEndRadius = self:GetSpecialValueFor("projectile_radius"),
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	})
	StartSoundEvent("Hero_ShadowDemon.ShadowPoison", caster)
end

function bane_spirit_poison:OnProjectileHit(target, loc)
	if target ~= nil then
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			damage = self:GetAbilityDamage(),
			damage_type = self:GetAbilityDamageType(),
			ability = self,
		})
		target:AddNewModifier(self:GetCaster(), self, "modifier_silence", {duration = self:GetSpecialValueFor("silence_duration")})
	end
end

function bane_spirit_poison:GetCastAnimation()
	return ACT_DOTA_ENFEEBLE
end