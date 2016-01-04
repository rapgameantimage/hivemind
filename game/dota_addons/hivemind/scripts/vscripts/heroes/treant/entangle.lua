entangle = class({})

function entangle:OnSpellStart()
	CreateModifierThinker(self:GetCaster(), self, "modifier_entangle_thinker", {duration = self:GetSpecialValueFor("delay")}, self:GetCursorPosition(), self:GetCaster():GetTeam(), false)
end

function entangle:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

---

LinkLuaModifier("modifier_entangle_thinker", "heroes/treant/entangle", LUA_MODIFIER_MOTION_NONE)
modifier_entangle_thinker = class({})

function modifier_entangle_thinker:OnDestroy()
	if not IsServer() then return end
	if self:GetParent():GetIntAttr("die_quietly") ~= 1 then
		SimpleAOE({
			caster = self:GetAbility():GetCaster(),
			center = self:GetParent():GetAbsOrigin(),
			radius = self:GetAbility():GetSpecialValueFor("radius"),
			modifiers = { modifier_entangle = { duration = self:GetAbility():GetSpecialValueFor("debuff_duration") } },
			ability = self:GetAbility()
		})
		local p = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_cast_growing_wood.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(p, 0, self:GetParent():GetAbsOrigin())
		StartSoundEventFromPosition("LoneDruid_SpiritBear.Entangle", self:GetParent():GetAbsOrigin())
	end
end

---

LinkLuaModifier("modifier_entangle", "heroes/treant/entangle", LUA_MODIFIER_MOTION_NONE)
modifier_entangle = class({})

function modifier_entangle:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_entangle:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_entangle:OnIntervalThink()
	print("Think")
	ApplyDamage({
		attacker = self:GetAbility():GetCaster(),
		victim = self:GetParent(),
		damage = self:GetAbility():GetSpecialValueFor("dps"),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility()
	})
end

function modifier_entangle:GetEffectName()
	return "particles/units/heroes/hero_lone_druid/lone_druid_bear_entangle_body.vpcf"
end

function modifier_entangle:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end