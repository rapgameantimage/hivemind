curse_mastery = class({})

function curse_mastery:GetIntrinsicModifierName()
	return "modifier_curse_mastery"
end

function curse_mastery:Cascade(ability, initial_target)
	local mastery_modifier = self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName())
	mastery_modifier:IncrementStackCount()
	local stacks = mastery_modifier:GetStackCount()
	ParticleManager:SetParticleControl(mastery_modifier.particle, 1, Vector(stacks, 0, 0))
	ApplyDamage({
		victim = initial_target,
		attacker = ability:GetCaster(),
		ability = ability,
		damage = self:GetSpecialValueFor("primary_target_damage_per_stack") * stacks,
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
	local caster = ability:GetCaster()
	local units = FindUnitsInRadius(caster:GetTeam(), initial_target:GetAbsOrigin(), nil, self:GetSpecialValueFor("cascade_radius_per_stack") * stacks, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for k,unit in pairs(units) do
		if unit ~= initial_target then
			local cascade_ability = caster:FindAbilityByName(ability:GetAbilityName() .. "_cascade")
			local proj = ({
				-- We have to use a dummy ability in order to tell which projectile is which.
				Ability = cascade_ability,
				EffectName = cascade_ability:GetParticleName(),
				vSpawnOrigin = initial_target:GetAbsOrigin(),
				Source = initial_target,
				Target = unit,
				iMoveSpeed = 450,
			})
			ProjectileManager:CreateTrackingProjectile(proj)
		end
	end
end

function curse_mastery:CascadeDamage(ability, target)
	ApplyDamage({
		victim = target,
		attacker = ability:GetCaster(),
		ability = ability,
		damage = self:GetCaster():FindModifierByName("modifier_curse_mastery"):GetStackCount() * self:GetSpecialValueFor("cascade_target_damage_per_stack"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end

function curse_mastery:Miss()
	local mod = self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName())
	for i = 1,self:GetSpecialValueFor("charges_lost_on_miss") do
		if mod:GetStackCount() > 0 then
			mod:DecrementStackCount()
			ParticleManager:SetParticleControl(mod.particle, 1, Vector(mod:GetStackCount(), 0, 0))
		end
	end
end

---

LinkLuaModifier("modifier_curse_mastery", "heroes/shadow_demon/curse_mastery", LUA_MODIFIER_MOTION_NONE)
modifier_curse_mastery = class({})

function modifier_curse_mastery:OnCreated()
	if not IsServer() then return end
	self.particle = ParticleManager:CreateParticle("particles/heroes/shadow_demon/curse_mastery.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_curse_mastery:IsHidden()
	return self:GetStackCount() < 1
end

function modifier_curse_mastery:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_EVENT_ON_RESPAWN}
end

function modifier_curse_mastery:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("movespeed_per_stack") * self:GetStackCount()
end

function modifier_curse_mastery:OnRespawn(event)
	if event.unit == self:GetParent() then
		self:SetStackCount(0)
		ParticleManager:SetParticleControl(self.particle, 1, Vector(0,0,0))
	end
end