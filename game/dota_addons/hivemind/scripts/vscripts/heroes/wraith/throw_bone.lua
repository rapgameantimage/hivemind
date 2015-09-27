throw_bone = class({})

function throw_bone:OnAbilityPhaseStart()
	-- Stupid workaround for ACT_DOTA_ATTACK not playing properly when interrupting a normal attack.
	StartAnimation(self:GetCaster(), {duration = 1, activity = ACT_DOTA_ATTACK})
	return true
end

function throw_bone:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

function throw_bone:OnSpellStart()
	local caster = self:GetCaster()
	EndAnimation(caster)
	self.direction = ((self:GetCursorPosition() - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	self.hit = false
	self.projectile = ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/heroes/wraith/bone.vpcf",
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = self.direction * 1200,
		fDistance = 1000,
		fStartRadius = 100,
		fEndRadius = 100,
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
	if not self.hit then
		self.hit = true
		if target ~= nil and not target:IsInvulnerable() then
			ApplyDamage({
				victim = target,
				attacker = self:GetCaster(),
				damage = self:GetAbilityDamage(),
				damage_type = self:GetAbilityDamageType(),
				ability = self,
			})
			target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_time")})
			local splinter = ParticleManager:CreateParticle("particles/heroes/wraith/bone_splinters.vpcf", PATTACH_WORLDORIGIN, target)
			ParticleManager:SetParticleControl(splinter, 0, loc)
			StartSoundEvent("WeaponImpact_Common.Wood", victim)
			Timers:CreateTimer(0.03, function()
				ProjectileManager:DestroyLinearProjectile(self.projectile)
			end)
		end
	end
end