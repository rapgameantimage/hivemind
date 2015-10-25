magnetizing_strike = class({})

function magnetizing_strike:OnToggle()
	if self:GetToggleState() == true then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_magnetizing_strike_passive", {})
	else
		self:GetCaster():RemoveModifierByName("modifier_magnetizing_strike_passive")
	end
end

---

LinkLuaModifier("modifier_magnetizing_strike_passive", "heroes/earth_spirit/magnetizing_strike", LUA_MODIFIER_MOTION_NONE)
modifier_magnetizing_strike_passive = class({})

function modifier_magnetizing_strike_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_magnetizing_strike_passive:OnAttackLanded(params)
	if params.attacker == self:GetParent()
		and params.attacker:GetTeam() ~= params.target:GetTeam()
		and not params.target:IsMagicImmune() then

		if self:GetParent():GetMana() < self:GetAbility():GetSpecialValueFor("mana_per_attack") then
			self:GetAbility():ToggleAbility()
			return
		end

		if not self:GetParent():HasModifier("modifier_magnetizing_strike_buff") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_magnetizing_strike_buff", {duration = self:GetAbility():GetSpecialValueFor("duration")})
			self:GetParent():FindModifierByName("modifier_magnetizing_strike_buff"):SetStackCount(1)
		else
			local mod = self:GetParent():FindModifierByName("modifier_magnetizing_strike_buff")
			mod:ForceRefresh()
			if mod:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
				mod:IncrementStackCount()
			end
		end

		if not params.target:HasModifier("modifier_magnetizing_strike_debuff") then
			params.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_magnetizing_strike_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration")})
			params.target:FindModifierByName("modifier_magnetizing_strike_debuff"):SetStackCount(1)
		else
			local mod = params.target:FindModifierByName("modifier_magnetizing_strike_debuff")
			mod:ForceRefresh()
			if mod:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
				mod:IncrementStackCount()
			end
		end

		ApplyDamage({
			attacker = params.attacker,
			victim = params.target,
			damage = self:GetAbility():GetAbilityDamage(),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
		})

		params.attacker:SpendMana(self:GetAbility():GetSpecialValueFor("mana_per_attack"), self:GetAbility())

		params.attacker:EmitSound("Hero_EarthSpirit.Magnetize.Target.Tick")
		ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_magnetize_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target)
	end
end

function modifier_magnetizing_strike_passive:GetEffectName()
	return "particles/heroes/earth_spirit/magnetic_strike_ambient.vpcf"
end

function modifier_magnetizing_strike_passive:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---

LinkLuaModifier("modifier_magnetizing_strike_debuff", "heroes/earth_spirit/magnetizing_strike", LUA_MODIFIER_MOTION_NONE)
modifier_magnetizing_strike_debuff = class({})

function modifier_magnetizing_strike_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_magnetizing_strike_debuff:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("movespeed_steal") * -1
end

function modifier_magnetizing_strike_debuff:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("attackspeed_steal") * -1
end

---

LinkLuaModifier("modifier_magnetizing_strike_buff", "heroes/earth_spirit/magnetizing_strike", LUA_MODIFIER_MOTION_NONE)
modifier_magnetizing_strike_buff = class({})

function modifier_magnetizing_strike_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_magnetizing_strike_buff:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("movespeed_steal")
end

function modifier_magnetizing_strike_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("attackspeed_steal")
end