ghostly_fireball = class({})

function ghostly_fireball:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	-- Wacky edge case:
	if caster:GetAbsOrigin() == target then
		self:OnProjectileHit(nil, target)
		return
	end

	-- 99.999% of the time:
	local speed = 900
	local maximum_possible_duration = self:GetCastRange(target, nil) / speed   	-- shouldn't actually be necessary; just a failsafe
	caster:AddNewModifier(self:GetCaster(), self, "modifier_ghostly_fireball_travel", {duration = maximum_possible_duration})
	caster:AddNoDraw()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), target)
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/heroes/wraith/ghostly_fireball.vpcf",
		vSpawnOrigin = caster:GetOrigin() + Vector(0, 0, 128),
		vVelocity = direction * 900,
		fDistance = DistanceBetweenVectors(caster:GetOrigin(), target),
		fStartRadius = 100,
		fEndRadius = 100,
		fExpireTime = GameRules:GetGameTime() + maximum_possible_duration,
		Source = caster,
	})
	caster:EmitSound("Hero_SkeletonKing.Hellfire_Blast")
end

function ghostly_fireball:OnProjectileThink(loc)
	self:GetCaster():SetAbsOrigin(GetGroundPosition(loc, self:GetCaster()))
end

function ghostly_fireball:OnProjectileHit(target, loc)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_ghostly_fireball_travel")
	caster:RemoveNoDraw()
	ParticleManager:CreateParticle("particles/frostivus_gameplay/frostivus_throne_wraith_king_explode.vpcf", PATTACH_ABSORIGIN, caster)
	SimpleAOE({
		caster = caster,
		ability = self,
		center = caster:GetAbsOrigin(),
		radius = self:GetSpecialValueFor("radius"),
		damage = self:GetAbilityDamage(),
		modifiers = {
			modifier_ghostly_fireball = {duration = self:GetSpecialValueFor("slow_duration")},
		},
	})
	caster:EmitSound("Hero_SkeletonKing.Hellfire_Blast")
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
end

function ghostly_fireball:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

---

LinkLuaModifier("modifier_ghostly_fireball_travel", "heroes/wraith/ghostly_fireball", LUA_MODIFIER_MOTION_NONE)
modifier_ghostly_fireball_travel = class({})

function modifier_ghostly_fireball_travel:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

---

LinkLuaModifier("modifier_ghostly_fireball", "heroes/wraith/ghostly_fireball", LUA_MODIFIER_MOTION_NONE)
modifier_ghostly_fireball = class({})

function modifier_ghostly_fireball:IsDebuff()
	return true
end

function modifier_ghostly_fireball:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_ghostly_fireball:GetModifierMoveSpeedBonus_Percentage()
	return ( -100 * self:GetRemainingTime() ) / self:GetDuration()
end

function modifier_ghostly_fireball:IsPurgable()
	return true
end