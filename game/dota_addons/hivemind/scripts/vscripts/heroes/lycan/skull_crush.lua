lycan_skull_crush = class({})
LinkLuaModifier("modifier_forced_animation", "heroes/lycan/modifier_forced_animation", LUA_MODIFIER_MOTION_NONE)

function lycan_skull_crush:OnAbilityPhaseStart()
	-- Stupid workaround for ACT_DOTA_ATTACK not playing properly when interrupting a normal attack.
	StartAnimation(self:GetCaster(), {duration = 1, activity = ACT_DOTA_ATTACK, rate = 0.6})
	return true
end

function lycan_skull_crush:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

function lycan_skull_crush:OnSpellStart()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_forced_animation") then caster:RemoveModifierByName("modifier_forced_animation") end
	local point = caster:GetAbsOrigin() + (caster:GetForwardVector() * self:GetSpecialValueFor("search_distance_from_self"))
	-- prioritize heroes:
	local units = FindUnitsInRadius(caster:GetTeam(), point, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	-- otherwise try basic units:
	if next(units) == nil then
		units = FindUnitsInRadius(caster:GetTeam(), point, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	end
	-- otherwise there's nobody to hit
	if next(units) == nil then
		return
	end

	-- Pick the closest unit in the table
	local closest_distance = 99999
	local closest = nil
	for i,unit in pairs(units) do
		local distance = CalcDistanceBetweenEntityOBB(caster, unit)
		if distance < closest_distance then
			closest_distance = distance
			closest = unit
		end
	end

	ApplyDamage({
		victim = closest,
		attacker = caster,
		damage_type = self:GetAbilityDamageType(),
		damage = self:GetAbilityDamage(),
		ability = self,
	})
	closest:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

	StartSoundEvent("Roshan.Bash", closest)
end