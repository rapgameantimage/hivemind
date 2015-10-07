repulsion = class({})

function repulsion:OnSpellStart()
	local caster = self:GetCaster()
	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for k,unit in pairs(units) do
		unit:AddNewModifier(caster, self, "modifier_repulsion", {duration = self:GetSpecialValueFor("push_duration")})
	end
	caster:EmitSound("DOTA_Item.ForceStaff.Activate")
end

function repulsion:GetCastAnimation()
	return ACT_DOTA_MIDNIGHT_PULSE
end

---

LinkLuaModifier("modifier_repulsion", "heroes/enigma/repulsion", LUA_MODIFIER_MOTION_NONE)
modifier_repulsion = class({})

function modifier_repulsion:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.last_position = self.parent:GetAbsOrigin()
	self.particles = ParticleManager:CreateParticle("particles/items_fx/force_staff.vpcf", PATTACH_POINT_FOLLOW, self.parent)
	self.direction = DirectionFromAToB(self:GetCaster():GetAbsOrigin(), self.last_position)
	self.facing_direction = self.direction * Vector(-1, -1, 0)
	self.velocity = self.direction * self:GetAbility():GetSpecialValueFor("push_distance") / self:GetDuration()
	self.tick_rate = 0.03
	self:StartIntervalThink(self.tick_rate)
	self:OnIntervalThink()
end

function modifier_repulsion:OnIntervalThink()
	local new_loc = self.parent:GetAbsOrigin() + (self.velocity * self.tick_rate)
	FindClearSpaceForUnit(self.parent, new_loc, false)
	local actual_loc = self.parent:GetAbsOrigin()
	self.parent:SetForwardVector(self.facing_direction)
	-- To test for collision, we compare the place we intended to go with the place we actually ended up when we used FindClearSpaceForUnit. If they're different, we must have collided with something.
	if new_loc * Vector(1, 1, 0) ~= actual_loc * Vector(1, 1, 0) then
		ApplyDamage({
			attacker = self:GetCaster(),
			victim = self.parent,
			damage = self:GetAbility():GetSpecialValueFor("collision_damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
		})
		self.parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", {duration = self:GetAbility():GetSpecialValueFor("collision_stun")})
		self.parent:EmitSound("Hero_Slardar.Bash")
		self:Destroy()
	end
end

function modifier_repulsion:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particles, false)
end

function modifier_repulsion:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_repulsion:IsHidden()
	return true
end

function modifier_repulsion:IsDebuff()
	return true
end

function modifier_repulsion:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_repulsion:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end