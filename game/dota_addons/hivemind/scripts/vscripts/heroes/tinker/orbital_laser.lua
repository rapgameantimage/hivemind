orbital_laser = class({})

function orbital_laser:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("Hero_Tinker.LaserAnim")
	return true
end

function orbital_laser:OnSpellStart()
	local thinker = CreateModifierThinker(self:GetCaster(), self, "modifier_orbital_laser_thinker", {duration = self:GetSpecialValueFor("duration")}, self:GetInitialPosition() + Vector(0, 0, 1024), self:GetCaster():GetTeam(), false)
	thinker:EmitSound("Hero_Tinker.Laser")
	AddFOWViewer(self:GetCaster():GetTeam(), self:GetInitialPosition(), 500, self:GetSpecialValueFor("duration"), false)
end

---

LinkLuaModifier("modifier_orbital_laser_thinker", "heroes/tinker/orbital_laser", LUA_MODIFIER_MOTION_NONE)
modifier_orbital_laser_thinker = class({})

function modifier_orbital_laser_thinker:OnCreated()
	if not IsServer() then return end

	self.particle = ParticleManager:CreateParticle("particles/heroes/tinker/orbital_laser.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.particle, 9, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.particle, 1, self:GetAbility():GetInitialPosition())
	
	self.focal_point = self:GetAbility():GetInitialPosition()
	self.tick_rate = 0.03
	self.direction = self:GetAbility():GetDirectionVector()
	self.distance_to_travel = DistanceBetweenVectors(self:GetAbility():GetInitialPosition(), self:GetAbility():GetTerminalPosition())
	self.duration = self:GetDuration()
	self.movement_per_tick = self.direction * self.distance_to_travel * self.tick_rate / self.duration

	self.dps = self:GetAbility():GetSpecialValueFor("damage_per_second")
	self.caster = self:GetAbility():GetCaster()

	self:StartIntervalThink(self.tick_rate)
end

function modifier_orbital_laser_thinker:OnIntervalThink()
	self.focal_point = self.focal_point + self.movement_per_tick
	ParticleManager:SetParticleControl(self.particle, 1, self.focal_point)

	SimpleAOE({
		center = self.focal_point,
		damage = self.dps * self.tick_rate,
		radius = 150,
		caster = self.caster,
	})

	GridNav:DestroyTreesAroundPoint(self.focal_point, 150, false)
end