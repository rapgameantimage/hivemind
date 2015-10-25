throw_rockling = class({})

function throw_rockling:CastFilterResultLocation(loc)
	if IsServer() then
		local caster = self:GetCaster()
		if DistanceBetweenVectors(caster:GetAbsOrigin(), loc) > self:GetCastRange(loc, nil) then
			return UF_FAIL_CUSTOM
		end
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("search_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, 0, false)
		for k,unit in pairs(units) do
			if unit ~= caster and not unit:IsNull() and unit:IsAlive() and unit:GetUnitName() == "npc_dota_earth_spirit_split_tiny" and not unit:HasModifier("modifier_throw_rockling_flying") then
				self.unit_to_throw = unit
				return UF_SUCCESS
			end
		end
		return UF_FAIL_CUSTOM
	end
end

function throw_rockling:GetCustomCastErrorLocation(loc)
	local caster = self:GetCaster()
	if DistanceBetweenVectors(caster:GetAbsOrigin(), loc) > self:GetCastRange(loc, nil) then
		return "#dota_hud_error_out_of_range"
	end
	return "#dota_hud_error_no_rockling_to_throw"
end

function throw_rockling:OnSpellStart()
	self:CastFilterResult()
	if not self.unit_to_throw then
		return
	end

	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local origin = caster:GetAbsOrigin()

	self.unit_to_throw:SetAbsOrigin(origin + Vector(0, 0, 64))
	self.unit_to_throw:AddNewModifier(caster, self, "modifier_throw_rockling_flying", {duration = 1, target_x = target.x, target_y = target.y, target_z = target.z})
	self.unit_to_throw:EmitSound("Hero_Tiny.Toss.Target")
	self.unit_to_throw = nil
	caster:EmitSound("Ability.TossThrow")
end

function throw_rockling:GetCastAnimation()
	return ACT_TINY_TOSS
end

function throw_rockling:GetAOERadius()
	return self:GetSpecialValueFor("damage_radius")
end

---

LinkLuaModifier("modifier_throw_rockling_flying", "heroes/earth_spirit/throw_rockling", LUA_MODIFIER_MOTION_NONE)
modifier_throw_rockling_flying = class({})

function modifier_throw_rockling_flying:IsHidden()
	return true
end

function modifier_throw_rockling_flying:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_throw_rockling_flying:OnCreated(info)
	if not IsServer() then return end
	self.tick_interval = 0.03
	self.lift = 2000				-- units/sec
	self.gravity = self.lift * -2	-- units/sec/sec
	self.parent = self:GetParent()
	self.target = Vector(info.target_x, info.target_y, info.target_z)
	self.direction_xy = DirectionFromAToB(self.parent:GetAbsOrigin(), self.target)
	self.xy_step = DistanceBetweenVectors(self.parent:GetAbsOrigin(), self.target) / self:GetDuration() * self.tick_interval * self.direction_xy
	self.ticks = 0
	self.max_ticks = math.floor(self:GetDuration() / self.tick_interval)
	self:StartIntervalThink(self.tick_interval)
end

function modifier_throw_rockling_flying:OnIntervalThink()
	local origin = self.parent:GetAbsOrigin()
	local desired_position = origin + self.xy_step
	desired_position = desired_position + Vector(0, 0, (self.lift * self.tick_interval) + (self.gravity * self.tick_interval * self.ticks / self.max_ticks))
	if desired_position.z < GetGroundHeight(desired_position, self.parent) then
		desired_position = GetGroundPosition(desired_position, self.parent)
	end
	self.parent:SetAbsOrigin(desired_position)
	self.ticks = self.ticks + 1
end

function modifier_throw_rockling_flying:OnDestroy()
	if not IsServer() then return end
	FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), false)
	SimpleAOE({
		center = self.parent:GetAbsOrigin(),
		radius = self:GetAbility():GetSpecialValueFor("damage_radius"),
		caster = self:GetAbility():GetCaster(),
		damage = self:GetAbility():GetAbilityDamage(),
		ability = self:GetAbility(),
	})
	SimpleAOE({
		center = self.parent:GetAbsOrigin(),
		radius = self:GetAbility():GetSpecialValueFor("damage_radius"),
		caster = self:GetAbility():GetCaster(),
		ability = self:GetAbility(),
		teamfilter = DOTA_UNIT_TARGET_TEAM_BOTH,
		modifiers = {
			modifier_throw_rockling_slow = {duration = self:GetAbility():GetSpecialValueFor("slow_duration")}
		}
	})
	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_toss_impact.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(p, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent))
	self.parent:EmitSound("Ability.TossImpact")
end

function modifier_throw_rockling_flying:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_throw_rockling_flying:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

---

LinkLuaModifier("modifier_throw_rockling_slow", "heroes/earth_spirit/throw_rockling", LUA_MODIFIER_MOTION_NONE)
modifier_throw_rockling_slow = class({})

function modifier_throw_rockling_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_throw_rockling_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow") * -1
end

function modifier_throw_rockling_slow:IsDebuff()
	return true
end

function modifier_throw_rockling_slow:IsPurgable()
	return true
end