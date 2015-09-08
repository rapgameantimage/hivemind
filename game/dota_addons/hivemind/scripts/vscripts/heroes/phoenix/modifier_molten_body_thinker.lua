modifier_molten_body_thinker = class({})

function modifier_molten_body_thinker:OnCreated()
	if IsServer() then
		self.tick_rate = 0.5
		self.dps = self:GetAbility():GetSpecialValueFor("dps")
		self.radius = self:GetAbility():GetSpecialValueFor("radius")
		self.caster = self:GetAbility():GetCaster()
		self.team = self:GetAbility():GetCaster():GetTeam()
		self:StartIntervalThink(self.tick_rate)
	end
end

function modifier_molten_body_thinker:OnIntervalThink()
	local units = FindUnitsInRadius(self.team, self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for i,unit in pairs(units) do
		if not unit:HasModifier("modifier_molten_body_immunity") then
			unit:AddNewModifier(self.caster, self:GetAbility(), "modifier_molten_body_immunity", {duration = self.tick_rate - 0.03})
			local dmg = {
				victim = unit,
				attacker = self.caster,
				damage = self.dps * self.tick_rate,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self:GetAbility(),
			}
			if self.caster:IsNull() then
				dmg.attacker = CreateModifierThinker(nil, self.ability, "modifier_postmortem_damage_source", {duration = 0.03}, self:GetParent():GetAbsOrigin(), self.team, false)
			end
			ApplyDamage(dmg)
		end
	end
end

function modifier_molten_body_thinker:GetEffectName()
	return "particles/heroes/phoenix/phoenix_lava_pool.vpcf"
end

function modifier_molten_body_thinker:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end