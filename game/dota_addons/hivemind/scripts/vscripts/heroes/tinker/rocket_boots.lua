rocket_boots = class({})

function rocket_boots:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_rocket_boots", {duration = 10})
end

---

LinkLuaModifier("modifier_rocket_boots", "heroes/tinker/rocket_boots", LUA_MODIFIER_MOTION_NONE)
modifier_rocket_boots = class({})

function modifier_rocket_boots:CheckState()
	return {[MODIFIER_STATE_FLYING] = true, [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_rocket_boots:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.tick_rate = 0.03
	self.upward_motion_total = 256
	self.rise_time = 0.5
	self.upward_moved = 0

	self.direction = self.parent:GetForwardVector()
	self.direction_locked = true
	self.allow_midair_turning = false
	self.direction_same_count = 0

	self:StartIntervalThink(self.tick_rate)

	self.flames1 = ParticleManager:CreateParticle("particles/heroes/tinker/rocket_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.flames1, 1, Vector(30, 0, 0))
	self.flames2 = ParticleManager:CreateParticle("particles/heroes/tinker/rocket_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.flames1, 1, Vector(-30, 0, 0))
end

function modifier_rocket_boots:OnIntervalThink()
	local origin = self.parent:GetAbsOrigin()
	-- print (self.direction_same_count .. " " .. tostring(self.direction_locked))
	
	if not self.direction_locked then
		local new_direction = self.parent:GetForwardVector()
		if self.direction == new_direction then
			self.direction_same_count = self.direction_same_count + 1
			if self.direction_same_count >= 2 then
				self.direction_locked = true
				self.allow_midair_turning = false
			end
		else
			self.direction_same_count = 0
			self.direction = new_direction
		end
	end

	local drift = origin + (self.direction * 450 * self.tick_rate)
	if self.upward_moved < self.upward_motion_total then
		self.upward_moved = self.upward_moved + self.upward_motion_total / self.rise_time * self.tick_rate
	end
	self.parent:SetAbsOrigin(GetGroundPosition(drift, self.parent) + Vector(0, 0, self.upward_moved))
end

function modifier_rocket_boots:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.flames1, false)
	ParticleManager:DestroyParticle(self.flames2, false)
end

function modifier_rocket_boots:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ORDER, MODIFIER_PROPERTY_DISABLE_TURNING}
end

function modifier_rocket_boots:GetModifierDisableTurning()
	if self.direction_locked and not self.allow_midair_turning then
		return 1
	else
		return 0
	end
end

function modifier_rocket_boots:OnOrder(order)
	if self.direction_locked then
		local unlock_direction_order_types = {
			[DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
			[DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
			[DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
			[DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
			[DOTA_UNIT_ORDER_CAST_POSITION] = true,
			[DOTA_UNIT_ORDER_CAST_TARGET] = true,
			[DOTA_UNIT_ORDER_CAST_TARGET_TREE] = true,
			[DOTA_UNIT_ORDER_DROP_ITEM] = true,
			[DOTA_UNIT_ORDER_GIVE_ITEM] = true,
			[DOTA_UNIT_ORDER_PICKUP_ITEM] = true,
			[DOTA_UNIT_ORDER_PICKUP_RUNE] = true,
		}
		if ((order.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET or order.order_type == DOTA_UNIT_ORDER_CAST_TARGET) and DistanceBetweenVectors(order.target:GetAbsOrigin(), self:GetParent():GetAbsOrigin()) < self:GetParent():GetAttackRange()) then
			self.allow_midair_turning = true
		elseif unlock_direction_order_types[order.order_type] then
			self.direction_locked = false
			self.allow_midair_turning = false
			self.direction_same_count = 0
		end
	end
end