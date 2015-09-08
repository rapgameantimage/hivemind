modifier_nightmare_orb_thinker = class({})

function modifier_nightmare_orb_thinker:OnCreated()
	if not IsServer() then return end

	self.ability = self:GetAbility()
	self.orb = self:GetParent()
	self.caster = self.orb:GetOwner()
	self.team = self.caster:GetTeam()
	self.dps = self.ability:GetSpecialValueFor("dps")
	self.pull_radius = self.ability:GetSpecialValueFor("pull_radius")
	self.damage_radius = self.ability:GetSpecialValueFor("damage_radius")
	self.units_pulling = {}

	self.particles = ParticleManager:CreateParticle("particles/heroes/bane/nightmare_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.orb)

	self:StartIntervalThink(0.03)
end

function modifier_nightmare_orb_thinker:OnIntervalThink()
	if not IsServer() then return end

	-- find units to pull
	local units = FindUnitsInRadius(self.team, self.orb:GetAbsOrigin(), nil, self.pull_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, 0, 0, false)
	for i,unit in pairs(units) do
		if unit:CanEntityBeSeenByMyTeam(self.orb) and not unit:HasModifier("modifier_nightmare_orb_pull") then
			local facing = unit:GetForwardVector()
			local vector_to_face_orb_directly = (self.orb:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
			-- https://github.com/Pizzalol/SpellLibrary/blob/SpellLibrary/game/dota_addons/spelllibrary/scripts/vscripts/heroes/hero_medusa/stone_gaze.lua
			local angle = math.abs(RotationDelta((VectorToAngles(vector_to_face_orb_directly)), VectorToAngles(facing)).y)
			if angle < 40 then
				unit:AddNewModifier(self.orb, self.ability, "modifier_nightmare_orb_pull", {})
				table.insert(self.units_pulling, unit)
			end
		end
	end

	-- find units to damage
	local units = FindUnitsInRadius(self.team, self.orb:GetAbsOrigin(), nil, self.damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, 0, 0, false)
	for i,unit in pairs(units) do
		ApplyDamage({
			victim = unit,
			attacker = self.caster,
			damage = self.dps * 0.03,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self.ability,
		})
	end
end

function modifier_nightmare_orb_thinker:OnDestroy()
	if not IsServer() then return end

	ParticleManager:DestroyParticle(self.particles, false)
	for i,unit in pairs(self.units_pulling) do
		if not unit:IsNull() then
			if unit:HasModifier("modifier_nightmare_orb_pull") then
				unit:RemoveModifierByName("modifier_nightmare_orb_pull")
			end
		end
	end
end

function modifier_nightmare_orb_thinker:DeclareFunctions()
	return { MODIFIER_PROPERTY_EVASION_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK }
end

function modifier_nightmare_orb_thinker:GetModifierEvasion_Constant()
	return 100
end

function modifier_nightmare_orb_thinker:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_nightmare_orb_thinker:GetModifierPhysical_ConstantBlock()
	return 99999
end
