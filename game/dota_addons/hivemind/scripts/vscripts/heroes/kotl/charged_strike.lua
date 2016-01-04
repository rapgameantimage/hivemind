charged_strike = class({})

function charged_strike:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_charged_strike", {duration = self:GetSpecialValueFor("buff_duration")})
	local ability = self:GetCaster():GetPlayerOwner():GetAssignedHero():FindAbilityByName("summon_spirits")
	if ability then
		ability:SpendSpirits(1)
	end
end

---

LinkLuaModifier("modifier_charged_strike", "heroes/kotl/charged_strike", LUA_MODIFIER_MOTION_NONE)
modifier_charged_strike = class({})

function modifier_charged_strike:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_charged_strike:OnAttackLanded(info)
	if info.attacker == self:GetParent() and not info.target:IsMagicImmune() then
		info.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_charged_strike_slow", {duration = self:GetAbility():GetSpecialValueFor("debuff_duration")})
		ApplyDamage({
			victim = info.target,
			attacker = self:GetParent(),
			damage = self:GetAbility():GetAbilityDamage(),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
		})
		info.target:EmitSound("Hero_StormSpirit.Overload")
		ParticleManager:CreateParticle("particles/units/heroes/hero_stormspirit/stormspirit_overload_discharge.vpcf", PATTACH_ABSORIGIN_FOLLOW, info.target)
		self:Destroy()
	end
end

function modifier_charged_strike:GetEffectName()
	return "particles/units/heroes/hero_wisp/wisp_overcharge.vpcf"
end

function modifier_charged_strike:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---

LinkLuaModifier("modifier_charged_strike_slow", "heroes/kotl/charged_strike", LUA_MODIFIER_MOTION_NONE)
modifier_charged_strike_slow = class({})

function modifier_charged_strike_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_charged_strike_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_pct") * -1
end