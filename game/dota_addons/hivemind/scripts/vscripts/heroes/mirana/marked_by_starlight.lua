marked_by_starlight = class({})

function marked_by_starlight:GetIntrinsicModifierName()
	return "modifier_marked_by_starlight"
end

---

LinkLuaModifier("modifier_marked_by_starlight", "heroes/mirana/marked_by_starlight", LUA_MODIFIER_MOTION_NONE)
modifier_marked_by_starlight = class({})

-- This part handles the charging up on attack

function modifier_marked_by_starlight:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_marked_by_starlight:OnAttackLanded(event)
	if event.attacker == self.parent and self:GetStackCount() < self.max_stacks then
		if self:GetStackCount() < 1 then
			self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
		end
		self:IncrementStackCount()
	end
end

function modifier_marked_by_starlight:IsHidden()
	return self:GetStackCount() < 1
end

-- This part drops the stars *~*~*~*~*~*~*~*~*

function modifier_marked_by_starlight:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.team = self.parent:GetTeam()
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	self.tick_interval = 0.5
	self.radius = self.ability:GetSpecialValueFor("radius")

	self:StartIntervalThink(self.tick_interval)
end

function modifier_marked_by_starlight:OnIntervalThink()
	if self:GetStackCount() < 1 or self.parent:HasModifier("modifier_hidden") or not self.ability:IsCooldownReady() then
		return
	end

	local units = FindUnitsInRadius(self.team, self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	
	if next(units) then
		local randomunit = units[RandomInt(1, #units)]
		randomunit:AddNewModifier(self.parent, self.ability, "modifier_marked_by_starlight_starfall", {duration = 0.3})
		ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, randomunit)
		randomunit:EmitSound("Ability.StarfallImpact")
		self:DecrementStackCount()
		self.ability:StartCooldown(self.ability:GetCooldown(1) - 0.03)
		if self:GetStackCount() < 1 then
			ParticleManager:DestroyParticle(self.particle, false)
		end
	end
end

---

LinkLuaModifier("modifier_marked_by_starlight_starfall", "heroes/mirana/marked_by_starlight", LUA_MODIFIER_MOTION_NONE)
modifier_marked_by_starlight_starfall = class({})

function modifier_marked_by_starlight_starfall:IsHidden()
	return true
end

function modifier_marked_by_starlight_starfall:OnDestroy()
	if not IsServer() then return end
	ApplyDamage({
		attacker = self:GetCaster(),
		victim = self:GetParent(),
		ability = self:GetAbility(),
		damage = self:GetAbility():GetSpecialValueFor("damage"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end