regrowth = class({})

function regrowth:GetIntrinsicModifierName()
	return "modifier_regrowth"
end

LinkLuaModifier("modifier_regrowth", "heroes/treant/regrowth", LUA_MODIFIER_MOTION_NONE)
modifier_regrowth = class({})

function modifier_regrowth:OnCreated()
	if not IsServer() then return end
	self.instances = {}
	self.tick_rate = 0.5
	self:StartIntervalThink(self.tick_rate)
end

function modifier_regrowth:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_regrowth:OnTakeDamage(event)
	if event.unit == self:GetParent() then
		self.instances[DoUniqueString("regrowth")] = { damage = event.damage, ticks_left = self:GetAbility():GetSpecialValueFor("regrowth_duration") * self.tick_rate }
	end
end

function modifier_regrowth:OnIntervalThink()
	local heal = 0
	for k,instance in pairs(self.instances) do
		heal = heal + (instance.damage * self:GetAbility():GetSpecialValueFor("regrowth_duration") * self.tick_rate)
		instance.ticks_left = instance.ticks_left - 1
	end
	self:GetParent():Heal(heal, self:GetParent())
end

function modifier_regrowth:IsHidden()
	for k,v in pairs(self.instances) do
		return false
	end
	return true
end