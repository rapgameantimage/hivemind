holy_infusion = class({})

function holy_infusion:CastFilterResultTarget(target)
	if target == self:GetCaster() then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function holy_infusion:GetCustomCastErrorTarget(target)
	return "#dota_hud_error_cant_cast_on_self"
end

function holy_infusion:OnSpellStart()
	self.caster = self:GetCaster()
	self.caster:EmitSound("Hero_Omniknight.Repel")
	self.target = self:GetCursorTarget()
	self.target:AddNewModifier(self.caster, self, "modifier_holy_infusion", {duration = self:GetChannelTime()})
	self.tether = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControlEnt(self.tether, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_attack1", self.caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.tether, 1, self.target, PATTACH_POINT_FOLLOW, "attach_attack1", self.target:GetAbsOrigin(), true)
end

function holy_infusion:OnChannelFinish(interrupted)
	self.target:RemoveModifierByNameAndCaster("modifier_holy_infusion", self.caster)
	ParticleManager:DestroyParticle(self.tether, false)
	self.caster:StopSound("Hero_Omniknight.Repel")
end

function holy_infusion:GetChannelAnimation()
	return ACT_DOTA_TELEPORT
end

---

LinkLuaModifier("modifier_holy_infusion", "heroes/omniknight/holy_infusion", LUA_MODIFIER_MOTION_NONE)
modifier_holy_infusion = class({})

function modifier_holy_infusion:CheckState()
	return {[MODIFIER_STATE_INVULNERABLE] = true}
end

function modifier_holy_infusion:OnCreated()
	if not IsServer() then return end
	self.tick_rate = 1
	self.glows = {}
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.parent = self:GetParent()
	self.team = self.caster:GetTeam()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.dps = self.ability:GetSpecialValueFor("dps")
	self:StartIntervalThink(self.tick_rate)
end

function modifier_holy_infusion:OnIntervalThink()
	local units = FindUnitsInRadius(self.team, self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	local hit = {}
	for k,unit in pairs(units) do
		ApplyDamage({
			victim = unit,
			attacker = self.caster,
			damage = self.dps * self.tick_rate,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self.ability,
		})
		hit[unit] = true
		if not self.glows[unit] then
			local p = ParticleManager:CreateParticle("particles/items2_fx/radiance.vpcf", PATTACH_POINT_FOLLOW, unit)
			ParticleManager:SetParticleControlEnt(p, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), false)
			self.glows[unit] = p
		end
	end
	for unit,particle in pairs(self.glows) do
		if not hit[unit] then
			ParticleManager:DestroyParticle(particle, false)
			self.glows[unit] = nil
		end
	end
end

function modifier_holy_infusion:OnDestroy()
	if not IsServer() then return end
	for unit,particle in pairs(self.glows) do
		ParticleManager:DestroyParticle(particle, false)
	end
end

function modifier_holy_infusion:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf"
end

function modifier_holy_infusion:GetAttachType()
	return PATTACH_POINT_FOLLOW
end