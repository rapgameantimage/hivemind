firewall = class({})

function firewall:OnSpellStart()
	local wall_entity_radius = 100
	local num_wall_thinkers = (self:GetSpecialValueFor("wall_width") / wall_entity_radius * 2) - 1
	local distance_between_thinkers = wall_entity_radius / 2
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local team = caster:GetTeam()
	local wall_duration = self:GetSpecialValueFor("wall_duration")
	
	local center = self:GetCursorPosition()
	local direction_to_center = ((center - origin):Normalized()) * Vector(1,1,0)
	-- A vector perpendicular to a,b is -b,a or b,-a.
	local perpendicular = Vector(direction_to_center.y * -1, direction_to_center.x, 0)
	local thinkers_per_side = (num_wall_thinkers - 1) / 2
	local next_thinker_loc = center + (perpendicular * Vector(distance_between_thinkers * thinkers_per_side, distance_between_thinkers * thinkers_per_side, 0))
	
	self.thinkers = {}
	-- create thinkers
	for i = 1,num_wall_thinkers do
		local thinker = CreateModifierThinker(caster, self, "modifier_firewall_thinker", {duration = wall_duration}, next_thinker_loc, team, false)
		if i == (num_wall_thinkers + 1) / 2 then
			local particles = ParticleManager:CreateParticle("particles/heroes/phoenix/firewall.vpcf", PATTACH_WORLDORIGIN, caster)
			-- Wow, I wish I had written some comments about this when I wrote it originally
			ParticleManager:SetParticleControl(particles, 0, center + (perpendicular * Vector(distance_between_thinkers * thinkers_per_side, distance_between_thinkers * thinkers_per_side, 0)))
			ParticleManager:SetParticleControl(particles, 1, center + (perpendicular * Vector(-1, -1, 0) * Vector(distance_between_thinkers * thinkers_per_side, distance_between_thinkers * thinkers_per_side, 0)))
			thinker:Attribute_SetIntValue("particles", particles)
		end
		table.insert(self.thinkers, thinker)
		next_thinker_loc = next_thinker_loc + (perpendicular * Vector(-1, -1, 0) * Vector(distance_between_thinkers, distance_between_thinkers, 0))
	end
end

function firewall:GetCastAnimation()
	return ACT_DOTA_SPAWN
end

-----

LinkLuaModifier("modifier_firewall_thinker", "heroes/phoenix/firewall", LUA_MODIFIER_MOTION_NONE)
modifier_firewall_thinker = class({})

function modifier_firewall_thinker:OnDestroy()
	if not IsServer() then return end
	if self:GetParent():Attribute_GetIntValue("particles", 0) ~= 0 then
		ParticleManager:DestroyParticle(self:GetParent():Attribute_GetIntValue("particles", 0), false)
	end
end

function modifier_firewall_thinker:OnCreated(info)
	if not IsServer() then return end
	self.tick_rate = 0.25
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.team = self.caster:GetTeam()
	self.wall_dps = self.ability:GetSpecialValueFor("wall_dps")
	self.burn_dps = self.ability:GetSpecialValueFor("burn_dps")
	self.burn_duration = self.ability:GetSpecialValueFor("burn_duration")
	self.damage_per_tick = (self.wall_dps - self.burn_dps) * self.tick_rate
	self.radius = 100
	self.parent = self:GetParent()
	self.origin = self.parent:GetAbsOrigin()

	self:StartIntervalThink(self.tick_rate)
end

function modifier_firewall_thinker:OnIntervalThink()
	local aoe = {
		caster = self.caster,
		ability = self.ability,
		radius = self.radius,
		center = self.origin,
		damage = self.damage_per_tick,
		modifiers = {
			modifier_firewall_burn = { duration = self.burn_duration },
			modifier_firewall_immunity = { duration = self.tick_rate - 0.03 },
		},
		customfilter = function(unit) return not unit:HasModifier("modifier_firewall_immunity") end,
	}
	if self.caster:IsNull() then
		aoe.caster = CreateModifierThinker(nil, self.ability, "modifier_postmortem_damage_source", {duration = 0.03}, self:GetParent():GetAbsOrigin(), self.team, false)
	end
	SimpleAOE(aoe)
end

-----

LinkLuaModifier("modifier_firewall_immunity", "heroes/phoenix/firewall", LUA_MODIFIER_MOTION_NONE)
modifier_firewall_immunity = class({})

function modifier_firewall_immunity:IsHidden()
	return true 
end

-----

LinkLuaModifier("modifier_firewall_burn", "heroes/phoenix/firewall", LUA_MODIFIER_MOTION_NONE)
modifier_firewall_burn = class({})

function modifier_firewall_burn:OnCreated()
	if not IsServer() then return end

	self.tick_rate = 0.25
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.dps = self.ability:GetSpecialValueFor("burn_dps")
	self.damage_per_tick = self.dps * self.tick_rate
	self.parent = self:GetParent()

	self:StartIntervalThink(self.tick_rate)
end

function modifier_firewall_burn:OnIntervalThink()
	ApplyDamage({
		attacker = self.caster,
		victim = self.parent,
		damage = self.damage_per_tick,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self.ability,
	})
end

function modifier_firewall_burn:GetEffectName()
	return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_firewall_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
