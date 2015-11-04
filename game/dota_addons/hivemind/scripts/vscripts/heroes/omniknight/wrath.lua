wrath = class({})

function wrath:OnSpellStart()
	self.channel_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	self.location_pfx = ParticleManager:CreateParticle("particles/econ/items/disruptor/disruptor_resistive_pinfold/disruptor_kf_formation_circglow.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(self.location_pfx, 0, self:GetCursorPosition())
	ParticleManager:SetParticleControl(self.location_pfx, 1, Vector(self:GetSpecialValueFor("storm_radius"), 0, 0))
	ParticleManager:SetParticleControl(self.location_pfx, 2, Vector(2, 0, 0))
	self.last_particle = GameRules:GetGameTime()
	self:GetCaster():EmitSound("Hero_Zuus.StaticField")
end

function wrath:OnChannelThink()
	if GameRules:GetGameTime() - self.last_particle > 0.33 then
		self.channel_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	end
end

function wrath:OnChannelFinish(interrupted)
	if not interrupted then
		local strikes = self:GetSpecialValueFor("lightning_strikes")
		local interval = 0.15
		CreateModifierThinker(self:GetCaster(), self, "modifier_wrath_thinker", {strikes = strikes, duration = strikes * interval, interval = interval, location_particle = self.location_pfx}, self:GetCursorPosition(), self:GetCaster():GetTeam(), false)
	else
		ParticleManager:DestroyParticle(self.location_pfx, false)
	end
	ParticleManager:DestroyParticle(self.channel_pfx, false)
end

function wrath:GetAOERadius()
	return self:GetSpecialValueFor("storm_radius")
end

function wrath:GetChannelAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

function wrath:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

function wrath:GetPlaybackRateOverride()
	return 0.6
end

---

LinkLuaModifier("modifier_wrath_thinker", "heroes/omniknight/wrath", LUA_MODIFIER_MOTION_NONE)
modifier_wrath_thinker = class({})

function modifier_wrath_thinker:OnCreated(info)
	if not IsServer() then return end
	self.location_particle = info.location_particle
	self.interval = info.interval
	self.strikes = info.strikes
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.damage = self.ability:GetSpecialValueFor("damage_per_strike")
	self.origin = self:GetParent():GetAbsOrigin()
	self.radius = self.ability:GetSpecialValueFor("storm_radius")
	self.damage_radius = self.ability:GetSpecialValueFor("damage_radius")
	self.cloud = ParticleManager:CreateParticle("particles/heroes/omniknight/wrath_cloud.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.cloud, 2, self.origin + Vector(0, 0, 600))
	self:StartIntervalThink(self.interval)
end

function modifier_wrath_thinker:OnIntervalThink()
	-- Pick a random point
	local point = self.origin + RandomVector(RandomFloat(0, self.radius))
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, self.caster)
	ParticleManager:SetParticleControl(particle, 0, point + Vector(0, 0, 600))
	ParticleManager:SetParticleControl(particle, 1, point)
	SimpleAOE({
		caster = self.caster,
		ability = self.ability,
		damage = self.damage,
		radius = self.damage_radius,
		center = point,
	})
	self:GetParent():EmitSound("Hero_Leshrac.Lightning_Storm")
end

function modifier_wrath_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.cloud, false)
	ParticleManager:DestroyParticle(self.location_particle, false)
end