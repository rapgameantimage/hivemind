sap = class({})

function sap:OnAbilityPhaseStart()
	-- Stupid workaround for ACT_DOTA_ATTACK not playing properly when interrupting a normal attack.
	StartAnimation(self:GetCaster(), {duration = 1, activity = ACT_DOTA_ATTACK, rate = 1.7})
	return true
end

function sap:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

function sap:OnSpellStart()
	EndAnimation(self:GetCaster())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/heroes/treant/sap.vpcf",
		vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
		vVelocity = DirectionFromAToB(self:GetCaster():GetAbsOrigin(), self:GetCursorPosition()) * 850,
		fDistance = 1200,
		fStartRadius = 100,
		fEndRadius = 100,
		Source = self:GetCaster(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
	})
end

function sap:OnProjectileHit(target, loc)
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_sap", {duration = self:GetSpecialValueFor("duration")})
		return true
	end
end

---

LinkLuaModifier("modifier_sap", "heroes/treant/sap", LUA_MODIFIER_MOTION_NONE)
modifier_sap = class({})

function modifier_sap:OnCreated()
	if IsServer() then
		self:SetStackCount(1)
	end
end

function modifier_sap:OnRefresh()
	if IsServer() and self:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
		self:IncrementStackCount()
	end
end

function modifier_sap:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT }
end

function modifier_sap:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attackspeed_slow_per_stack") * self:GetStackCount() * -1
end

function modifier_sap:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("movespeed_slow_per_stack") * self:GetStackCount() * -1
end

function modifier_sap:GetEffectName()
	return "particles/heroes/treant/sap_debuff.vpcf"
end