retribution = class({})

function retribution:CastFilterResultTarget(target)
	if not IsServer() then return end
	local recent_damage = self:GetCaster():FindModifierByName("modifier_retribution_passive").recent_damage
	if recent_damage then
		if recent_damage > 0 then
			return UF_SUCCESS
		end
	end
	return UF_FAIL_CUSTOM
end

function retribution:GetCustomCastErrorTarget(target)
	return "#dota_hud_error_no_recent_damage"
end

function retribution:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self.damage = caster:FindModifierByName("modifier_retribution_passive").recent_damage
	ProjectileManager:CreateTrackingProjectile({
		Source = caster,
		Target = target,
		Ability = self,
		iMoveSpeed = 475,
		--bProvidesVision = true,
		--iVisionRadius = 300,
		--iVisionTeamNumber = caster:GetTeam(),
		vSpawnOrigin = caster:GetAbsOrigin() + DirectionFromAToB(caster:GetAbsOrigin(), target:GetAbsOrigin()) * 64,
		EffectName = "particles/nothing.vpcf",
	})
	self.particle = ParticleManager:CreateParticle("particles/heroes/omniknight/retribution.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(self.particle, 3, caster:GetAbsOrigin() + DirectionFromAToB(caster:GetAbsOrigin(), target:GetAbsOrigin()) * 64)
	ParticleManager:SetParticleControl(self.particle, 10, Vector(self.damage, 0, 0))
	caster:EmitSound("Hero_Oracle.FortunesEnd.Channel")
end

function retribution:OnProjectileHit(target, loc)
	ApplyDamage({
		victim = target,
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	})
	ParticleManager:DestroyParticle(self.particle, false)
	self:GetCaster():StopSound("Hero_Oracle.FortunesEnd.Channel")
	target:EmitSound("Hero_Oracle.FortunesEnd.Attack")
end

function retribution:OnProjectileThink(loc)
	ParticleManager:SetParticleControl(self.particle, 3, loc)
end

function retribution:GetIntrinsicModifierName()
	return "modifier_retribution_passive"
end

function retribution:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

---

LinkLuaModifier("modifier_retribution_passive", "heroes/omniknight/retribution", LUA_MODIFIER_MOTION_NONE)
modifier_retribution_passive = class({})

function modifier_retribution_passive:OnCreated()
	self.recent_damage = 0
end

function modifier_retribution_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_retribution_passive:OnTakeDamage(info)
	if info.unit == self:GetParent() then
		local dmg = info.damage
		self.recent_damage = self.recent_damage + dmg
		Timers:CreateTimer(5, function()
			self.recent_damage = self.recent_damage - dmg
		end)
	end
end

function modifier_retribution_passive:IsHidden()
	return true
end