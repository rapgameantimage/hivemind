aeonic_curse = class({})

function aeonic_curse:OnSpellStart()
	local caster = self:GetCaster()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/nothing.vpcf",
		vSpawnOrigin = caster:GetOrigin() + direction * 50,
		vVelocity = direction * 1000,
		fDistance = 1000,
		fStartRadius = 150,
		fEndRadius = 150,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
		bProvidesVision = true,
		iVisionRadius = 800,
		iVisionTeamNumber = caster:GetTeam(),
	})
	caster:EmitSound("Hero_FacelessVoid.TimeWalk")
	-- Dummy unit to attach the time walk particle to
	self.dummy = CreateModifierThinker(caster, self, "modifier_nonexistent", {duration = 0.06}, caster:GetAbsOrigin(), caster:GetTeam(), false)
	self.dummy:SetForwardVector(direction)
	self.particle = ParticleManager:CreateParticle("particles/econ/items/faceless_void/faceless_void_jewel_of_aeons/fv_time_walk_pentagon_jewel.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.dummy)
end

function aeonic_curse:OnProjectileThink(loc)
	if self.dummy and not self.dummy:IsNull() then
		self.dummy:FindModifierByName("modifier_nonexistent"):SetDuration(0.06, true)
		self.dummy:SetAbsOrigin(GetGroundPosition(loc, nil))
	end
end

function aeonic_curse:OnProjectileHit(target, loc)
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_aeonic_curse", {duration = self:GetSpecialValueFor("duration")})
		self:GetCaster():FindAbilityByName("curse_mastery"):Cascade(self, target)
		target:EmitSound("Hero_FacelessVoid.TimeLockImpact")
		return true
	else
		self:GetCaster():FindAbilityByName("curse_mastery"):Miss()
	end
end

function aeonic_curse:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

---

aeonic_curse_cascade = class({})

function aeonic_curse_cascade:OnProjectileHit(target, loc)
	local caster = self:GetCaster()
	local aeonic_curse = caster:FindAbilityByName("aeonic_curse")
	target:AddNewModifier(caster, aeonic_curse, "modifier_aeonic_curse", {duration = aeonic_curse:GetSpecialValueFor("duration")})
	caster:FindAbilityByName("curse_mastery"):CascadeDamage(self, target)
	ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_demonic_purge_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function aeonic_curse_cascade:GetParticleName()
	return "particles/econ/items/puck/puck_alliance_set/puck_base_attack_aproset.vpcf"
end

---

LinkLuaModifier("modifier_aeonic_curse", "heroes/shadow_demon/aeonic_curse", LUA_MODIFIER_MOTION_NONE)
modifier_aeonic_curse = class({})

function modifier_aeonic_curse:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.tick = 0
	self.last_origin = self.parent:GetAbsOrigin()
	self.last_fv = self.parent:GetForwardVector()
	self.started = false
	self.movement = {}
	self.tick_rate = 0.03
	self:StartIntervalThink(self.tick_rate)
	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_demonic_purge_debuff.vpcf", PATTACH_POINT_FOLLOW, self.parent)
end

function modifier_aeonic_curse:OnIntervalThink()
	self.tick = self.tick + 1

	local origin = self.parent:GetAbsOrigin()
	local fv = self.parent:GetForwardVector()
	if origin ~= self.last_origin then
		if not self.ignore_last_move then
			self.movement[self.tick] = self.parent:GetForwardVector()
		end
		self.ignore_last_move = false

		-- if unit is moving, sum up their vectors from the last second and adjust their position accordingly based on their movespeed.
		-- thus, the unit actually isn't "walking" at all while under the influence of this modifier. (of course they can still move via other abilities, but it will be adjusted)
		local drift = Vector(0, 0, 0)
		local start
		if self.tick < 33 then
			start = 0
		else
			start = self.tick - 33
		end
		for i = start,start+32 do
			if self.movement[i] then
				drift = drift + self.movement[i]
			end
		end
		local movespeed = self.parent:GetMoveSpeedModifier(self.parent:GetBaseMoveSpeed())
		drift = drift:Normalized() * movespeed * self.tick_rate

		local new_origin = origin + movespeed * self.tick_rate * DirectionFromAToB(origin, self.last_origin) + drift

		-- Find a clear space if they are on the ground, just set directly if they are airborne
		if GetGroundPosition(origin, self.parent) ~= origin then
			self.parent:SetAbsOrigin(new_origin)
		else
			FindClearSpaceForUnit(self.parent, new_origin, false)
			if self.parent:GetAbsOrigin() ~= GetGroundPosition(new_origin, self.parent) then
				print(tostring(self.parent:GetAbsOrigin()) .. " vs . " .. tostring(GetGroundPosition(new_origin, self.parent)))
				self.ignore_last_move = true
			end
		end
		self.last_origin = self.parent:GetAbsOrigin()
		self.last_fv = fv
	end
end

function modifier_aeonic_curse:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particle, false)
end

function modifier_aeonic_curse:IsDebuff()
	return true
end

function modifier_aeonic_curse:IsPurgable()
	return true
end