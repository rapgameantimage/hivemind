-- phantom creates a ghost and shoves it in the target direction
-- the modifier_phantom that is added to that unit does all the rest of the actual work

phantom = class({})

function phantom:OnSpellStart()
	local phantom_speed = 700
	local phantom_travel_time = 1.5

	local caster = self:GetCaster()
	local caster_origin = caster:GetAbsOrigin()
	local target = self:GetCursorPosition()
	local direction = (target - caster_origin):Normalized() * Vector(1,1,0)

	-- create a phantom 100 units in front of the caster
	local phantom = CreateUnitByName("npc_dota_phantom", caster_origin + (direction * 100), false, caster, caster, caster:GetTeam())
	ParticleManager:CreateParticle("particles/heroes/bane/phantom_poof.vpcf", PATTACH_ABSORIGIN_FOLLOW, phantom)
	phantom:EmitSound("Hero_DeathProphet.Exorcism.Damage")
	phantom:AddNewModifier(caster, self, "modifier_phantom", {duration = phantom_travel_time, haunt_duration = self:GetSpecialValueFor("duration")})
	phantom:SetForwardVector(direction)
	Physics:Unit(phantom)
	phantom:SetPhysicsFriction(0)
	phantom:FollowNavMesh(false)
	phantom:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	phantom:SetAutoUnstuck(false)
	phantom:AddPhysicsVelocity(direction * phantom_speed)

	-- modifier_phantom checks for collisions
end

function phantom:GetCastAnimation()
	return ACT_DOTA_ENFEEBLE
end

---

LinkLuaModifier("modifier_phantom", "heroes/bane/phantom", LUA_MODIFIER_MOTION_NONE)
modifier_phantom = class({})

function modifier_phantom:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_phantom:OnCreated(info)
	if not IsServer() then return end

	self.haunt_duration = info.haunt_duration
	self.parent = self:GetParent()
	self.team = self.parent:GetTeam()
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.search_radius = self.ability:GetSpecialValueFor("search_radius")
	self.draw = true
	self.damage = self.ability:GetSpecialValueFor("damage")
	self.tick_rate = 0.1

	self:StartIntervalThink(self.tick_rate)
end

function modifier_phantom:OnDestroy()
	if not IsServer() then return end
	if self.target ~= nil and not self.target:IsNull() and self.target:HasModifier("modifier_phantom_target") then
		self.target:RemoveModifierByName("modifier_phantom_target")
	end
	if self.draw then
		self.parent:AddNoDraw()
	end
	self.parent:ForceKill(false)
end

function modifier_phantom:OnIntervalThink()
	-- If we don't have a target, try to find one
	if self.target == nil then
		local units = FindUnitsInRadius(self.team, self.parent:GetAbsOrigin(), nil, 128, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
		if units ~= nil and next(units) ~= nil then
			self.target = table.remove(units)
			self.target_team = self.target:GetTeam()
			self.target:AddNewModifier(self.caster, self.ability, "modifier_phantom_target", {})
			self.parent:SetPhysicsVelocity(Vector(0,0,0))
			self:SetDuration(self.haunt_duration, true)
			ExecuteOrderFromTable({
				OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
				UnitIndex = self.parent:GetEntityIndex(),
				TargetIndex = self.target:GetEntityIndex(),
			})
			self.parent:EmitSound("Hero_DeathProphet.Exorcism.Damage")
		end
	-- If we do have a target, check to see if we can deal damage
	else
		-- If the target has vanished (due to transformation) or died, we should stop
		if self.target:IsNull() or not self.target:IsAlive() or self.target:HasModifier("modifier_hidden") then
			self:Destroy()
		-- Check if we're close enough to the target. If not, we should re-follow
		elseif DistanceBetweenVectors(self.target:GetAbsOrigin(), self.parent:GetAbsOrigin()) > self.search_radius then
			ExecuteOrderFromTable({
				OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
				UnitIndex = self.parent:GetEntityIndex(),
				TargetIndex = self.target:GetEntityIndex(),
			})
			-- Possibly we were hidden before, in which case we should un-hide
			if not self.draw then
				self.parent:RemoveNoDraw()
				self.draw = true
				ParticleManager:CreateParticle("particles/heroes/bane/phantom_poof.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
				self.parent:EmitSound("Hero_PhantomLancer.Doppelganger.Appear")
			end
		-- Otherwise we should check to deal damage
		else
			ExecuteOrderFromTable({
				OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
				UnitIndex = self.parent:GetEntityIndex(),
				TargetIndex = self.target:GetEntityIndex(),
			})
			-- See if the target is near units
			local units = FindUnitsInRadius(self.target_team, self.target:GetAbsOrigin(), nil, self.search_radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
			-- We can't just check if units is nil because it will return the target as well! So we need to loop through the table.
			local found_another_unit = false
			for k,unit in pairs(units) do
				if unit ~= self.target and not unit:IsNull() and unit:IsAlive() and unit:GetUnitName() ~= "npc_dota_phantom" and unit:GetUnitName() ~= "npc_dota_nightmare_orb" then
					found_another_unit = true
					break
				end
			end 
			if found_another_unit then
				-- Since we found units, we can't deal damage, and we should hide ourselves if we haven't already.
				if self.draw then
					self.parent:AddNoDraw()
					self.draw = false
					ParticleManager:CreateParticle("particles/heroes/bane/phantom_poof.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
					self.parent:EmitSound("Hero_PhantomLancer.Doppelwalk")
				end
			else
				-- We didn't find any nearby units, so we can deal damage.
				ApplyDamage({
					damage = self.damage * self.tick_rate,
					damage_type = DAMAGE_TYPE_MAGICAL,
					victim = self.target,
					attacker = self.caster,
					ability = self.ability,
				})
				-- Unhide ourselves if we haven't.
				if not self.draw then
					self.parent:RemoveNoDraw()
					self.draw = true
					ParticleManager:CreateParticle("particles/heroes/bane/phantom_poof.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
					self.parent:EmitSound("Hero_PhantomLancer.Doppelganger.Appear")
				end
			end
		end
	end
end

---

-- This modifier just gives vision
LinkLuaModifier("modifier_phantom_target", "heroes/bane/phantom", LUA_MODIFIER_MOTION_NONE)
modifier_phantom_target = class({})

function modifier_phantom_target:IsHidden()
	return true
end

function modifier_phantom_target:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_phantom_target:GetModifierProvidesFOWVision()
	return 1
end
