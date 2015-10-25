earthen_passage = class({})

function earthen_passage:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_earthen_passage_travel", {duration = self:GetSpecialValueFor("travel_time")})
	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_spawn.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(p, 1, caster:GetAbsOrigin())
	caster:EmitSound("Hero_Meepo.Poof.Channel")
end

---

LinkLuaModifier("modifier_earthen_passage_travel", "heroes/earth_spirit/earthen_passage", LUA_MODIFIER_MOTION_NONE)
modifier_earthen_passage_travel = class({})

-- 3 phases:
-- Phase 1: sinking (vulnerable)
-- Phase 2: underground (invulnerable)
-- Phase 3: rising (vulnerable)

function modifier_earthen_passage_travel:OnCreated()
	if not IsServer() then return end

	self.phase = 1
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.target = self.ability:GetCursorPosition()
	self.rise_fall = 1500
	self.direction = DirectionFromAToB(self.parent:GetAbsOrigin(), self.target)
	self.distance = DistanceBetweenVectors(self.parent:GetAbsOrigin(), self.target)

	self:StartIntervalThink(0.03)
end

function modifier_earthen_passage_travel:OnIntervalThink()
	local origin = self.parent:GetAbsOrigin()
	if self.phase == 1 then
		self.parent:SetAbsOrigin(origin - Vector(0, 0, self.rise_fall * 0.03))
		if self:GetElapsedTime() >= 0.2 then
			self.phase = 2
			self.parent:AddNoDraw()
			self.parent:SetAbsOrigin(self.parent:GetAbsOrigin() - Vector(0, 0, 200))
		end
	elseif self.phase == 2 then
		self.parent:SetAbsOrigin(origin + self.direction * self.distance * 0.03 / 0.6)
		if self:GetElapsedTime() >= 0.8 then
			self.phase = 3
			self.parent:RemoveNoDraw()
			self.parent:SetAbsOrigin(self.parent:GetAbsOrigin() + Vector(0, 0, 200))
		end
	elseif self.phase == 3 then
		if not self.end_particle then
			self.end_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_meepo/meepo_poof_end.vpcf", PATTACH_WORLDORIGIN, self.parent)
			ParticleManager:SetParticleControl(self.end_particle, 0, self.target)
		end
		self.parent:SetAbsOrigin(origin + Vector(0, 0, self.rise_fall * 0.03))
	end
end

function modifier_earthen_passage_travel:OnDestroy()
	if not IsServer() then return end
	FindClearSpaceForUnit(self.parent, self.target, false)
	SimpleAOE({
		caster = self.parent,
		center = self.target,
		radius = self.ability:GetSpecialValueFor("debuff_radius"),
		ability = self.ability,
		modifiers = {
			modifier_silence = { duration = self.ability:GetSpecialValueFor("debuff_duration") }
		}
	})
end

function modifier_earthen_passage_travel:CheckState()
	local state = {[MODIFIER_STATE_STUNNED] = true}
	if self.phase == 2 then
		state[MODIFIER_STATE_INVULNERABLE] = true
		state[MODIFIER_STATE_NO_HEALTH_BAR] = true
		state[MODIFIER_STATE_INVISIBLE] = true
	end
	return state
end

function modifier_earthen_passage_travel:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_earthen_passage_travel:GetOverrideAnimation()
	if self.phase == 3 then
		return ACT_DOTA_SPAWN
	end
end

function modifier_earthen_passage_travel:IsHidden()
	return true
end

---

LinkLuaModifier("modifier_earthen_passage_debuff", "heroes/earth_spirit/earthen_passage", LUA_MODIFIER_MOTION_NONE)
modifier_earthen_passage_debuff = class({})

function modifier_earthen_passage_debuff:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true}
end