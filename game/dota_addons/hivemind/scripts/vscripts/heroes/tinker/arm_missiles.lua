arm_missiles = class({})

function arm_missiles:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_arm_missiles", {duration = self:GetSpecialValueFor("buff_duration")})
	caster:SetModifierStackCount("modifier_arm_missiles", caster, self:GetSpecialValueFor("missile_count"))
	caster:EmitSound("Hero_Tinker.MissileAnim")
end

function arm_missiles:OnProjectileHit(target, loc)
	ApplyDamage({
		victim = target,
		attacker = self:GetCaster(),
		damage = self:GetAbilityDamage(),
		damage_type = self:GetAbilityDamageType(),
		ability = self,
	})
	SimpleAOE({
		center = target:GetAbsOrigin(),
		radius = self:GetSpecialValueFor("half_damage_radius"),
		damage = self:GetAbilityDamage() / 2,
		damage_type = self:GetAbilityDamageType(),
		caster = self:GetCaster(),
		ability = self,
		customfilter = function(unit)
			return unit ~= target 
		end,
	})
	ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_missle_explosion.vpcf", PATTACH_POINT, target)
	StartSoundEvent("Hero_Tinker.Heat-Seeking_Missile.Impact", target)
end

---

LinkLuaModifier("modifier_arm_missiles", "heroes/tinker/arm_missiles", LUA_MODIFIER_MOTION_NONE)
modifier_arm_missiles = class({})

function modifier_arm_missiles:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK}
end

function modifier_arm_missiles:OnAttack(info)
	if info.attacker == self:GetParent() and info.target:GetTeam() ~= self:GetParent():GetTeam() then
		self:DecrementStackCount()
		ProjectileManager:CreateTrackingProjectile({
			EffectName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf",
			Ability = self:GetAbility(),
			Target = info.target,
			Source = info.attacker,
			bDodgeable = true,
			bProvidesVision = true,
			vSpawnOrigin = info.attacker:GetAbsOrigin(),
			iMoveSpeed = 450,
			iVisionRadius = 500,
			iVisionTeamNumber = info.attacker:GetTeam(),
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		})
		info.attacker:EmitSound("Hero_Tinker.Heat-Seeking_Missile")
		if self:GetStackCount() < 1 then
			self:Destroy()
		end
	end
end