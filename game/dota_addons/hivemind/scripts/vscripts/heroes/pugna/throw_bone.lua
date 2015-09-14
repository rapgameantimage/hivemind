throw_bone = class({})

function throw_bone:OnSpellStart()
	local caster = self:GetCaster()
	local direction = ((self:GetCursorPosition() - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/heroes/pugna/bone.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = direction * 1200,
		fDistance = 1000,
		fStartRadius = 128,
		fEndRadius = 128,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
	})
	ApplyDamage({
		victim = caster,
		attacker = caster,
		damage = self:GetSpecialValueFor("health_cost"),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	})
end

function throw_bone:OnProjectileHit(target, loc)
	if target ~= nil and not target:IsInvulnerable() then
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			damage = self:GetAbilityDamage()
			damage_type = self:GetAbilityDamageType(),
			ability = self,
		})
		target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_time")})
	end
end