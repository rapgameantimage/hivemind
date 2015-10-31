missile_swarm = class({})

function missile_swarm:OnSpellStart()
	local delay = 0.35
	local rockets = self:GetSpecialValueFor("rockets")

	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_missile_swarm", {duration = delay * rockets + delay / 2})
	caster:EmitSound("Hero_Tinker.Rearm")

	local rocket_count = 0
	Timers:CreateTimer(delay, function()
		StartAnimation(caster, {activity = ACT_DOTA_CAST_ABILITY_2, rate = 3, duration = delay * rockets})
		local direction = caster:GetForwardVector()
		ProjectileManager:CreateLinearProjectile({
			Ability = self,
			EffectName = "particles/heroes/tinker/missile_swarm.vpcf",
			vSpawnOrigin = caster:GetOrigin(),
			vVelocity = direction * 1000,
			fDistance = 1500,
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
		caster:EmitSound("Hero_Tinker.Heat-Seeking_Missile")
		rocket_count = rocket_count + 1
		if rocket_count < rockets then
			return delay
		end
	end)

	caster:EmitSound("Hero_Tinker.MissileAnim")
end

function missile_swarm:OnProjectileHit(target, loc)
	if not target then return end

	local radius = self:GetSpecialValueFor("radius")
	local origin = target:GetAbsOrigin()
	local units = FindUnitsInRadius(self:GetCaster():GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k,unit in pairs(units) do
		ApplyDamage({
			victim = unit,
			attacker = self:GetCaster(),
			ability = self,
			damage = self:GetAbilityDamage() * ((radius - DistanceBetweenVectors(origin, unit:GetAbsOrigin())) / radius),
			damage_type = DAMAGE_TYPE_MAGICAL,
		})
	end
	local explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_missle_explosion.vpcf", PATTACH_WORLDORIGIN, target)
	ParticleManager:SetParticleControl(explosion, 0, loc + Vector(0, 0, 70))
	StartSoundEvent("Hero_Tinker.Heat-Seeking_Missile.Impact", target)
	return true
end

function missile_swarm:GetCastAnimation()
	return ACT_DOTA_IDLE
end

---

LinkLuaModifier("modifier_missile_swarm", "heroes/tinker/missile_swarm", LUA_MODIFIER_MOTION_NONE)
modifier_missile_swarm = class({})

function modifier_missile_swarm:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_SILENCED] = true}
end

function modifier_missile_swarm:GetEffectName()
	return "particles/heroes/tinker/missile_swarm_ground.vpcf"
end

function modifier_missile_swarm:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end