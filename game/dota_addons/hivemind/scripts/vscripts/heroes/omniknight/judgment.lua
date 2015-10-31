judgment = class({})

function judgment:OnSpellStart()
	self.counter_duration = 8
	self.stacks_to_shackle = 3

	local caster = self:GetCaster()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror.vpcf",
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = direction * 1000,
		fDistance = 1000,
		fStartRadius = 50,
		fEndRadius = 150,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = false,
		--bProvidesVision = true,
		--bObstructedVision = false,
		--iVisionRadius = 400,
		--iVisionTeamNumber = caster:GetTeam(),
	})
	caster:EmitSound("Hero_VengefulSpirit.WaveOfTerror")
end

function judgment:OnProjectileHit(target, loc)
	if target then
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			damage = self:GetAbilityDamage(),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self,
		})
		target:AddNewModifier(self:GetCaster(), self, "modifier_judgment_counter", {duration = self.counter_duration})
		if not target:HasModifier("modifier_judgment_shackle") and target:GetModifierStackCount("modifier_judgment_counter", self:GetCaster()) >= self.stacks_to_shackle then
			-- The target has exceeded the permitted number of judgment stacks, so lock 'em up, boys.
			target:AddNewModifier(self:GetCaster(), self, "modifier_judgment_shackle", {duration = self:GetSpecialValueFor("shackle_duration")})
			target:RemoveModifierByName("modifier_judgment_counter")
			target:EmitSound("Hero_ShadowShaman.Shackles.Cast")
		end
	end
end

function judgment:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

---

LinkLuaModifier("modifier_judgment_counter", "heroes/omniknight/judgment", LUA_MODIFIER_MOTION_NONE)
modifier_judgment_counter = class({})

function modifier_judgment_counter:OnCreated()
	self.counter_duration = 8
	if not IsServer() then return end
	self.stacks = {}
	self:ForceRefresh()
	self:StartIntervalThink(0.25)
end

function modifier_judgment_counter:OnRefresh()
	if not IsServer() then return end
	self.stacks[DoUniqueString("judgment_stack")] = GameRules:GetGameTime()
	self:IncrementStackCount()
end

function modifier_judgment_counter:OnIntervalThink()
	for k,stack_time in pairs(self.stacks) do
		if stack_time + self.counter_duration <= GameRules:GetGameTime() then
			self.stacks[k] = nil
			self:DecrementStackCount()
		end
	end
	if self:GetStackCount() < 1 then
		self:Destroy()
	end
end

---

LinkLuaModifier("modifier_judgment_shackle", "heroes/omniknight/judgment", LUA_MODIFIER_MOTION_NONE)
modifier_judgment_shackle = class({})

function modifier_judgment_shackle:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.shackle_location = self.parent:GetAbsOrigin()
	self.shackle_leash_distance = self:GetAbility():GetSpecialValueFor("shackle_leash_distance")
	self:StartIntervalThink(0.03)
	self.particle = ParticleManager:CreateParticle("particles/heroes/omniknight/judgment_shackle.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.particle, 3, self.shackle_location)
	ParticleManager:SetParticleControlEnt(self.particle, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), false)
	self.particle2 = ParticleManager:CreateParticle("particles/heroes/omniknight/judgment_shackle_source.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.particle2, 3, self.shackle_location)
end

function modifier_judgment_shackle:OnIntervalThink()
	local origin = self:GetParent():GetAbsOrigin()
	if DistanceBetweenVectors(origin, self.shackle_location) > self.shackle_leash_distance then
		self.parent:SetAbsOrigin(self.shackle_location + DirectionFromAToB(self.shackle_location, origin) * self.shackle_leash_distance + Vector(0, 0, origin.z - self.shackle_location.z))
	end
end

function modifier_judgment_shackle:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.particle, false)
	ParticleManager:DestroyParticle(self.particle2, false)
end

function modifier_judgment_shackle:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true}
end