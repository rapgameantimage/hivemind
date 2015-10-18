discharge = class({})

function discharge:OnSpellStart()
	local caster = self:GetCaster()
	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false)
	caster:EmitSound("Hero_Rattletrap.Power_Cogs_Impact")
	for k,unit in pairs(units) do
		if not unit:IsInvulnerable() then
			unit:AddNewModifier(caster, self, "modifier_discharge", {duration = self:GetSpecialValueFor("push_duration")})
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_rattletrap/rattletrap_cog_attack.vpcf", PATTACH_POINT_FOLLOW, unit)
			ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
			unit:ReduceMana(self:GetSpecialValueFor("mana_burn"))
			ApplyDamage({
				damage = self:GetAbilityDamage(),
				damage_type = DAMAGE_TYPE_MAGICAL,
				victim = unit,
				attacker = caster,
				ability = self,
			})
		end
	end
end

function discharge:GetCastAnimation()
	return ACT_DOTA_RATTLETRAP_POWERCOGS
end

---

LinkLuaModifier("modifier_discharge", "heroes/tinker/discharge", LUA_MODIFIER_MOTION_NONE)
modifier_discharge = class({})

function modifier_discharge:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.direction = DirectionFromAToB(self.caster:GetAbsOrigin(), self.parent:GetAbsOrigin())
	self.distance = self:GetAbility():GetSpecialValueFor("push_distance")
	self.velocity = self.distance / self:GetDuration() * self.direction

	self:StartIntervalThink(0.03)
	self:OnIntervalThink()
end

function modifier_discharge:OnIntervalThink()
	local destination = self.parent:GetAbsOrigin() + self.velocity * 0.03
	if not GridNav:IsBlocked(destination) and GridNav:IsTraversable(destination) then
		self.parent:SetAbsOrigin(destination)
	end
end

function modifier_discharge:OnDestroy()
	if not IsServer() then return end
	FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
end

function modifier_discharge:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_discharge:IsHidden()
	return true
end

function modifier_discharge:IsStunDebuff()
	return true
end

function modifier_discharge:IsDebuff()
	return true
end

function modifier_discharge:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_discharge:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end