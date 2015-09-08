modifier_lacerate_bleeding = class({})

function modifier_lacerate_bleeding:OnCreated(info)
	if IsServer() then
		self.damage_instances = {}
		self.ability = self:GetAbility()
		self.bleed_time = self.ability:GetSpecialValueFor("bleed_time")
		self.bleed_interval = self.ability:GetSpecialValueFor("bleed_interval")
		self.caster = self.ability:GetCaster()
		self.max_ticks = self.bleed_time / self.bleed_interval
		self.damage_multiplier = 1 / self.max_ticks
		self.parent = self:GetParent()
		self.damage_type = self.ability:GetAbilityDamageType()

		self:AddLacerateDamageInstance(info.damage)
		self:StartIntervalThink(self.bleed_interval)
	end
end

function modifier_lacerate_bleeding:AddLacerateDamageInstance(damage_to_deal)
	if IsServer() then
		local key = DoUniqueString("")
		self.damage_instances[key] = {damage = damage_to_deal, times_ticked = 0}
		self:SetDuration(self.bleed_time, true)
	end
end

function modifier_lacerate_bleeding:OnIntervalThink()
	local damage_total = 0

	-- Loop through the table of damage instances to figure out how much to deal
	for key,table in pairs(self.damage_instances) do
		damage_total = damage_total + (table["damage"] * self.damage_multiplier)
		local ticks = table["times_ticked"] + 1
		-- See if it's time to remove this instance from the table
		if ticks >= self.max_ticks then
			self.damage_instances[key] = nil
		else
			table["times_ticked"] = ticks
		end
	end

	ApplyDamage({
		victim = self.parent,
		attacker = self.caster,
		damage = damage_total,
		damage_type = self.damage_type,
		ability = self.ability,
		damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
	})

	-- If we have no damage instances left, remove the modifier.
	if next(self.damage_instances) == nil then
		self:Destroy()
	end
end

function modifier_lacerate_bleeding:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture_constant.vpcf"
end

function modifier_lacerate_bleeding:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
