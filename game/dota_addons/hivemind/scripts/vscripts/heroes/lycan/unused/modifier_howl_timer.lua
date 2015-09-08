modifier_howl_timer = class({})

function modifier_howl_timer:OnCreated()
	if not IsServer() then return end

	print("created on " .. self:GetParent():GetEntityIndex() .. " (a "  .. self:GetParent():GetUnitName() .. ")")
	self.time_started = GameRules:GetGameTime()
	self.stacks_applied = 0
end

function modifier_howl_timer:OnIntervalThink()
	if not IsServer() then return end

	local ability = self:GetAbility()
	local time_in_radius = GameRules:GetGameTime() - self.time_started
	print(time_in_radius)
	if time_in_radius >= self.stacks_applied + 1 then
		if eslf:GetParent():HasModifier("modifier_howl_counter") then
			local counter = self:GetParent():FindModifierByName("modifier_howl_counter")
			counter:IncrementStackCount()
			counter:SetDuration(ability:GetSpecialValueFor("stack_duration"))
			if counter:GetStackCount() >= ability:GetSpecialValueFor("stacks_required_for_sleep") and not self:GetParent():HasModifier("modifier_howl_sleeping") and not self:GetParent():HasModifier("modifier_howl_insomnia") then
				self:GetParent():AddNewModifier(ability:GetCaster(), ability, "modifier_howl_sleeping", {duration = ability:GetSpecialValueFor("sleep_duration")})
			end
		else
			self:GetParent():AddNewModifier(ability:GetCaster(), ability, "modifier_howl_counter", {duration = ability:GetSpecialValueFor("stack_duration")})
		end
	end
end