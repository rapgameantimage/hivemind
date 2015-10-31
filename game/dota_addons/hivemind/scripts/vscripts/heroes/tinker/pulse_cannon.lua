pulse_cannon = class({})

function pulse_cannon:OnSpellStart()
	local caster = self:GetCaster()
	self.direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
	end
	if self.projectile then
		ProjectileManager:DestroyLinearProjectile(self.projectile)
	end
	self.projectile = ProjectileManager:CreateLinearProjectile({
		Ability = self,
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = self.direction * 550,
		fDistance = 1200,
		fStartRadius = 100,
		fEndRadius = 100,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
		--bProvidesVision = true,
		--iVisionRadius = 500,
		--iVisionTeamNumber = caster:GetTeam(),
	})
	self.particle = ParticleManager:CreateParticle("particles/heroes/tinker/pulse.vpcf", PATTACH_POINT, caster)
	caster:EmitSound("Hero_StormSpirit.ElectricVortexCast")
end

function pulse_cannon:OnProjectileThink(loc)
	ParticleManager:SetParticleControl(self.particle, 0, loc + Vector(0, 0, GetGroundHeight(loc, nil) + 40))
end

function pulse_cannon:OnProjectileHit(target, loc)
	if target then
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			ability = self,
			damage = self:GetAbilityDamage(),
			damage_type = DAMAGE_TYPE_MAGICAL,
		})
		target:AddNewModifier(self:GetCaster(), self, "modifier_pulse_cannon", {duration = self:GetSpecialValueFor("debuff_duration")})
		if DistanceBetweenVectors(loc, self:GetCaster():GetAbsOrigin()) < self:GetSpecialValueFor("self_affect_distance") then
			ApplyDamage({
				victim = self:GetCaster(),
				attacker = self:GetCaster(),
				ability = self,
				damage = self:GetAbilityDamage(),
				damage_type = DAMAGE_TYPE_MAGICAL,
			})
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_pulse_cannon", {duration = self:GetSpecialValueFor("debuff_duration")})
		end
		ProjectileManager:DestroyLinearProjectile(self.projectile)
		StartSoundEvent("Hero_StormSpirit.StaticRemnantExplode", target)
		local hit_effect = ParticleManager:CreateParticle("particles/heroes/tinker/pulse_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		AddFOWViewer(self:GetCaster():GetTeam(), target:GetAbsOrigin(), 300, 2, false)
	end
	ParticleManager:DestroyParticle(self.particle, false)
	return true
end

function pulse_cannon:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

---

LinkLuaModifier("modifier_pulse_cannon", "heroes/tinker/pulse_cannon", LUA_MODIFIER_MOTION_NONE)
modifier_pulse_cannon = class({})

function modifier_pulse_cannon:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_pulse_cannon:GetEffectName()
	return "particles/heroes/tinker/pulse_target.vpcf"
end

function modifier_pulse_cannon:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end