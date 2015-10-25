quake = class({})

function quake:OnSpellStart()
	self.thinker = CreateModifierThinker(self:GetCaster(), self, "modifier_quake_thinker", {duration = self:GetSpecialValueFor("duration")}, self:GetCursorPosition(), self:GetCaster():GetTeam(), false)
	self:GetCaster():SwapAbilities("quake", "move_quake", false, true)
end

---

LinkLuaModifier("modifier_quake_thinker", "heroes/earth_spirit/quake", LUA_MODIFIER_MOTION_NONE)
modifier_quake_thinker = class({})

function modifier_quake_thinker:OnCreated()
	if not IsServer() then return end

	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.parent = self:GetParent()

	self.tick_rate = 0.5
	self.max_ticks = math.floor(self:GetDuration() / self.tick_rate)
	self.ticks = 0

	local start_radius = self.ability:GetSpecialValueFor("radius_start")
	local end_radius = self.ability:GetSpecialValueFor("radius_end")
	self.radius_step = (end_radius - start_radius) / self.max_ticks
	self.radius = start_radius

	local start_dps = self.ability:GetSpecialValueFor("dps_start")
	local end_dps = self.ability:GetSpecialValueFor("dps_end")
	self.dps_step = (end_dps - start_dps) / self.max_ticks
	self.dps = start_dps

	local movespeed = self.ability:GetSpecialValueFor("quake_movespeed")
	self.movement_step = movespeed * self.tick_rate

	self:StartIntervalThink(self.tick_rate)
end

function modifier_quake_thinker:OnIntervalThink()
	local origin = self.parent:GetAbsOrigin()
	if self.destination then
		if DistanceBetweenVectors(origin, self.destination) < self.movement_step then
			self.parent:SetAbsOrigin(self.destination)
			self.destination = nil
		else
			self.parent:SetAbsOrigin(origin + DirectionFromAToB(origin, self.destination) * self.movement_step)
		end
	end

	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, origin)
	ParticleManager:SetParticleControl(p, 1, Vector(self.radius, self.radius, self.radius))
	StartSoundEvent("Hero_EarthSpirit.StoneRemnant.Impact", self.parent)

	SimpleAOE({
		center = self.parent:GetAbsOrigin(),
		caster = self.caster,
		radius = self.radius,
		damage = self.dps * self.tick_rate,
		ability = self.ability,
		modifiers = {
			modifier_quake_slow = { duration = self.ability:GetSpecialValueFor("slow_linger") }
		},
	})

	self.radius = self.radius + self.radius_step
	self.dps = self.dps + self.dps_step
end

function modifier_quake_thinker:OnDestroy()
	if not IsServer() then return end
	self.caster:SwapAbilities("quake", "move_quake", true, false)
end

---

LinkLuaModifier("modifier_quake_slow", "heroes/earth_spirit/quake", LUA_MODIFIER_MOTION_NONE)
modifier_quake_slow = class({})

function modifier_quake_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_quake_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow") * -1
end

---

move_quake = class({})

function move_quake:OnSpellStart()
	local caster = self:GetCaster()
	local quake_ability = caster:FindAbilityByName("quake")
	local thinker = quake_ability.thinker
	if thinker then
		thinker:FindModifierByName("modifier_quake_thinker").destination = self:GetCursorPosition()
	end
end