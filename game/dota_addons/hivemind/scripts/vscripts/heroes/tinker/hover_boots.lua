-- IMPORTANT NOTE:
-- This ability requires the table hover_boots_movement to be initialized beforehand (is currently initialized in gamemode.lua to make sure it does not initialize multiple times)
-- It also requires FilterManager (in helper_functions.lua) in order to cleanly account for multiple instances of this ability

hover_boots = class({})

function hover_boots:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_hover_boots", {duration = self:GetSpecialValueFor("duration")})
end

---

LinkLuaModifier("modifier_hover_boots", "heroes/tinker/hover_boots", LUA_MODIFIER_MOTION_NONE)
modifier_hover_boots = class({})

-- The player is actually rooted while this modifier is applied.
-- To move them, we filter orders that require movement and register where the player is going, then update their position every frame.

function modifier_hover_boots:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_hover_boots:OnCreated()
	self.speed = self:GetAbility():GetSpecialValueFor("speed")
	if not IsServer() then return end
	self.peak_hover_height = 64
	self.rise_per_tick = 8
	self.hover_height = 0
	self.falling = false
	self.parent = self:GetParent()

	self.filter_index = FilterManager:AddFilter("order", function(context, order)
		local move_to_specified_position = {
			[DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
			[DOTA_UNIT_ORDER_ATTACK_MOVE] = true,			
		--	[DOTA_UNIT_ORDER_CAST_POSITION] = true,	
			[DOTA_UNIT_ORDER_DROP_ITEM] = true,
		}
		local target_order_types = {
			[DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
		--	[DOTA_UNIT_ORDER_CAST_TARGET] = true,
		--	[DOTA_UNIT_ORDER_CAST_TARGET_TREE] = true,
		--	[DOTA_UNIT_ORDER_GIVE_ITEM] = true,
		--	[DOTA_UNIT_ORDER_PICKUP_ITEM] = true,
		--	[DOTA_UNIT_ORDER_PICKUP_RUNE] = true,
		}
		local attack_target_order_types = {
		--	[DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
		}
		local stop_types = {
			[DOTA_UNIT_ORDER_STOP] = true,
			[DOTA_UNIT_ORDER_HOLD_POSITION] = true,
		}
		if move_to_specified_position[order.order_type] then
			hover_boots_movement[order.units["0"]] = {movetype = "point", target = Vector(order.position_x, order.position_y, order.position_z)}
		elseif target_order_types[order.order_type] then
			hover_boots_movement[order.units["0"]] = {movetype = "unit", target = EntIndexToHScript(order.entindex_target)}
		--elseif attack_target_order_types[order.order_type] then
		--	hover_boots_movement[order.units["0"]] = {movetype = "attack_unit", target = EntIndexToHScript(order.entindex_target)}
		elseif stop_types[order.order_type] then
			hover_boots_movement[order.units["0"]] = nil
		end
		return true
	end, self)

	self.parent:EmitSound("Hero_Tinker.MechaBoots.Loop")

	self:StartIntervalThink(0.03)
	self:OnIntervalThink(0)
end

function modifier_hover_boots:OnRefresh()
	self.falling = false
end

function modifier_hover_boots:OnIntervalThink()
	if self.parent:HasModifier("modifier_hidden") then
		self:Destroy()
	end

	local origin = self.parent:GetAbsOrigin()
	local new_origin = origin

	if self:GetDieTime() - GameRules:GetGameTime() < 0.03 * (self.peak_hover_height / self.rise_per_tick) then
		self.falling = true
	end

	if self.hover_height < self.peak_hover_height and not self.falling then
		self.hover_height = self.hover_height + self.rise_per_tick
	elseif self.falling and origin.z > GetGroundHeight(origin, self.parent) then
		self.hover_height = self.hover_height - self.rise_per_tick
	end

	if self.parent:IsStunned() then
		return
	end

	local movement = hover_boots_movement[self.parent:GetEntityIndex()]
	
	if movement then
		if movement.movetype == "point" then
			destination = movement.target
		elseif movement.movetype == "unit" then
			destination = movement.target:GetAbsOrigin()
		--elseif movement.movetype == "attack_unit" then
		--	if DistanceBetweenVectors(movement.target:GetAbsOrigin(), origin) > self.parent:GetAttackRange() then
		--		destination = movement.target:GetAbsOrigin() + DirectionFromAToB(movement.target:GetAbsOrigin(), origin) * self.parent:GetAttackRange()
		--	else
		--		destination = origin
		--	end
		end

		if destination.x == origin.x and destination.y == origin.y then
			hover_boots_movement[self.parent:GetEntityIndex()] = nil 
		elseif DistanceBetweenVectors(origin, destination) < self.speed * 0.03 then
			new_origin = destination
		else
			local direction = DirectionFromAToB(origin, destination)
			new_origin = new_origin + (direction * self.speed * 0.03)
		end
	end

	new_origin = GetGroundPosition(new_origin, self.parent) + Vector(0, 0, self.hover_height)
	
	GridNav:DestroyTreesAroundPoint(new_origin, 128, false)
	self.parent:SetAbsOrigin(new_origin)
end

function modifier_hover_boots:OnDestroy()
	if not IsServer() then return end
	FilterManager:RemoveFilter(self.filter_index)
	hover_boots_movement[self.parent:GetEntityIndex()] = nil
	FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin() - Vector(0, 0, self.hover_height), true)
	StopSoundOn("Hero_Tinker.MechaBoots.Loop", self.parent)
end

function modifier_hover_boots:GetEffectName()
	return "particles/heroes/tinker/hover_boots.vpcf"
end

function modifier_hover_boots:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-- This is purely cosmetic to make the movespeed that shows up in the UI be correct. Actual movement is handled above.

function modifier_hover_boots:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE}
end

function modifier_hover_boots:GetModifierMoveSpeed_Absolute()
	return self.speed
end