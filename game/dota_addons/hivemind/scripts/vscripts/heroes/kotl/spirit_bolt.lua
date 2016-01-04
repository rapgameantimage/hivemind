spirit_bolt = class({})

function spirit_bolt:CastFilterResultLocation(loc)
	if not IsServer() then return end
	local mod = self:GetCaster():FindModifierByName("modifier_summon_spirits")
	local ab = self:GetCaster():FindAbilityByName("summon_spirits")
	if not mod or not mod.center or mod:GetStackCount() < self:GetSpecialValueFor("spirit_cost") then
		return UF_FAIL_CUSTOM
	else
		local distance = DistanceBetweenVectors(loc, mod.center:GetAbsOrigin())
		if distance > ab:GetSpecialValueFor("outer_radius") or distance < ab:GetSpecialValueFor("min_radius") then
			return UF_FAIL_CUSTOM
		end
	end
	return UF_SUCCESS
end

function spirit_bolt:GetCustomCastErrorLocation(loc)
	local mod = self:GetCaster():FindModifierByName("modifier_summon_spirits")
	local ab = self:GetCaster():FindAbilityByName("summon_spirits")
	if not mod or not mod.center or mod:GetStackCount() < self:GetSpecialValueFor("spirit_cost") then
		return "#dota_hud_error_not_enough_spirits"
	else
		return "#dota_hud_error_not_in_orbit"
	end
end

function spirit_bolt:OnSpellStart()
	local caster = self:GetCaster()
	caster:FindAbilityByName("summon_spirits"):SpendSpirits(self:GetSpecialValueFor("spirit_cost"))
	caster:AddNewModifier(caster, self, "modifier_spirit_bolt_travel", {duration = 1})
	caster:AddNoDraw()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = direction * 2000,
		fDistance = DistanceBetweenVectors(caster:GetAbsOrigin(), self:GetCursorPosition()),
		fStartRadius = 250,
		fEndRadius = 250,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = false,
	})
end

function spirit_bolt:OnProjectileHit(target, loc)
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_spirit_bolt_blind", {duration = self:GetSpecialValueFor("blind_duration")})
	else
		FindClearSpaceForUnit(self:GetCaster(), loc, false)
		self:GetCaster():RemoveModifierByName("modifier_spirit_bolt_travel")
		self:GetCaster():RemoveNoDraw()
	end
end

function spirit_bolt:OnProjectileThink(loc)
	self:GetCaster():SetAbsOrigin(GetGroundPosition(loc, self:GetCaster()))
end

---

LinkLuaModifier("modifier_spirit_bolt_travel", "heroes/kotl/spirit_bolt", LUA_MODIFIER_MOTION_NONE)
modifier_spirit_bolt_travel = class({})

function modifier_spirit_bolt_travel:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

---

LinkLuaModifier("modifier_spirit_bolt_blind", "heroes/kotl/spirit_bolt", LUA_MODIFIER_MOTION_NONE)
modifier_spirit_bolt_blind = class({})

function modifier_spirit_bolt_blind:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_spirit_bolt_blind:GetModifierMiss_Percentage()
	return self:GetAbility():GetSpecialValueFor("blind_miss_pct")
end