hookshot = class({})

function hookshot:OnSpellStart()
	local caster = self:GetCaster()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/units/heroes/hero_rattletrap/rattletrap_hookshot.vpcf",		-- Doesn't actually do anything
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = direction * 4000,
		fDistance = self:GetSpecialValueFor("max_distance"),
		fStartRadius = 125,
		fEndRadius = 125,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
	})
	self.p = ParticleManager:CreateParticle("particles/units/heroes/hero_rattletrap/rattletrap_hookshot_b.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.p, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.p, 3, caster:GetAbsOrigin() + Vector(0, 0, 64))
	caster:EmitSound("Hero_Rattletrap.Hookshot.Fire")
end

function hookshot:OnProjectileHit(target, loc)
	if not self.retracting then
		if target then
			if not target:IsInvulnerable() and target:IsAlive() and target ~= self:GetCaster() then
				self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_hookshot_travel", {duration = 0.5, target = target:GetEntityIndex(), particle = self.p})
				if target:GetTeam() ~= self:GetCaster():GetTeam() then
					target:AddNewModifier(self:GetCaster(), self, "modifier_hookshot_hit_stun", {duration = 0.5})
				end
				ParticleManager:SetParticleControl(self.p, 3, target:GetAbsOrigin() + Vector(0, 0, 64) - (DirectionFromAToB(self:GetCaster():GetAbsOrigin(), target:GetAbsOrigin()) * 30))
				StartSoundEvent("Hero_Rattletrap.Hookshot.Impact", target)
				return true
			end
		else
			ParticleManager:DestroyParticle(self.p, true)
		end
	end
end

function hookshot:OnProjectileThink(loc)
	ParticleManager:SetParticleControl(self.p, 3, loc + Vector(0, 0, 64))
	print(tostring(loc))
end

function hookshot:GetCastAnimation()
	return ACT_DOTA_RATTLETRAP_HOOKSHOT_START
end

---

LinkLuaModifier("modifier_hookshot_travel", "heroes/tinker/hookshot", LUA_MODIFIER_MOTION_NONE)
modifier_hookshot_travel = class({})

function modifier_hookshot_travel:OnCreated(info)
	if not IsServer() then return end
	self.target = EntIndexToHScript(info.target)
	self.p = info.particle
	self.units_hit = {}
	self:StartIntervalThink(0.03)
end

function modifier_hookshot_travel:OnIntervalThink()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local target_origin = self.target:GetAbsOrigin()
	local direction = DirectionFromAToB(origin, target_origin)
	if DistanceBetweenVectors(origin, target_origin) > 4000 * 0.03 then
		caster:SetAbsOrigin(origin + direction * 4000 * 0.03)
	else
		FindClearSpaceForUnit(caster, target_origin + direction * -35, true)
		self:GetCaster():RemoveModifierByName("modifier_hookshot_travel")
	end
	self:HookAOE()
end

function modifier_hookshot_travel:OnDestroy()
	if not IsServer() then return end
	local caster = self:GetCaster()
	self.target:RemoveModifierByName("modifier_hookshot_hit_stun")
	self:HookAOE()
	ParticleManager:DestroyParticle(self.p, true)
	if caster:GetTeam() ~= self.target:GetTeam() then
		caster:EmitSound("Hero_Rattletrap.Hookshot.Damage")
	end
end

function modifier_hookshot_travel:HookAOE()
	local caster = self:GetAbility():GetCaster()
	SimpleAOE({
		caster = caster,
		center = caster:GetAbsOrigin(),
		radius = 175,
		ability = self:GetAbility(),
		damage = self:GetAbility():GetAbilityDamage(),
		damage_type = DAMAGE_TYPE_MAGICAL,
		modifiers = { modifier_stunned = { duration = self:GetAbility():GetSpecialValueFor("stun_duration") } },
		customfilter = function(unit)
			if not self.units_hit[unit] then
				self.units_hit[unit] = true
				return true
			else
				return false
			end
		end,
	})
end

function modifier_hookshot_travel:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_DISARMED] = true}
end

function modifier_hookshot_travel:IsHidden()
	return true
end

function modifier_hookshot_travel:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_hookshot_travel:GetOverrideAnimation()
	return {ACT_DOTA_RATTLETRAP_HOOKSHOT_LOOP}
end

---

LinkLuaModifier("modifier_hookshot_hit_stun", "heroes/tinker/hookshot", LUA_MODIFIER_MOTION_NONE)
modifier_hookshot_hit_stun = class({})

function modifier_hookshot_hit_stun:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_hookshot_hit_stun:IsDebuff()
	return true
end

function modifier_hookshot_hit_stun:IsStunDebuff()
	return true
end

function modifier_hookshot_travel:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_hookshot_travel:GetOverrideAnimation()
	return {ACT_DOTA_DISABLED}
end