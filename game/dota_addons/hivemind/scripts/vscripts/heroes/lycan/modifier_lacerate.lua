modifier_lacerate = class({})

function modifier_lacerate:OnCreated()
	if IsServer() then
		self.attacks = 1
		self.ability = self:GetAbility()
		self.attacks_per_stack = self.ability:GetSpecialValueFor("attacks_per_stack")
		self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
		self.bleed_percent_per_stack = self.ability:GetSpecialValueFor("bleed_percent_per_stack")
		self.bleed_time = self.ability:GetSpecialValueFor("bleed_time")
		self.caster = self.ability:GetCaster()
		self:StartIntervalThink(self.attacks_per_stack)
	end
end

function modifier_lacerate:OnRefresh()
	if IsServer() then
		if self:GetStackCount() < self.max_stacks then
			self.attacks = self.attacks + 1
			self:SetStackCount(math.min(self.max_stacks, math.floor(self.attacks / self.attacks_per_stack)))
		end
	end
end

function modifier_lacerate:OnIntervalThink()
	self.attacks = self.attacks - self.max_stacks
	self:DecrementStackCount()
	if self.attacks <= 0 then
		self:Destroy()
	end
end

function modifier_lacerate:IsPurgable()
	return true
end

function modifier_lacerate:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_fury_swipes_debuff.vpcf"
end

function modifier_lacerate:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_lacerate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_lacerate:OnTakeDamage(info)
	if IsServer() then
		-- Make sure that: 
		-- (a) the unit taking damage is actually this unit;
		-- (b) the damage it's taking isn't from lacerate or some other source we can't multiply;
		-- (c) we actually have at least 1 stack of lacerate
		if info.unit == self:GetParent() and info.damage_flags ~= DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS and self:GetStackCount() > 0 then
			local original_damage = info.damage
			local total_lacerate_damage = original_damage * self.bleed_percent_per_stack * self:GetStackCount() / 100
			if info.unit:HasModifier("modifier_lacerate_bleeding") then
				-- If we just add a lacerate modifier every time we take damage, the game crashes. Oops.
				-- Well, I *guess* it could have been because I made an infinite loop by accident without realizing.
				-- But it's cleaner to keep track of everything in one modifier anyway.
				info.unit:FindModifierByName("modifier_lacerate_bleeding"):AddLacerateDamageInstance(total_lacerate_damage)
			else
				info.unit:AddNewModifier(self.caster, self.ability, "modifier_lacerate_bleeding", {damage = total_lacerate_damage, duration = self.bleed_time})
			end
		end
	end
end