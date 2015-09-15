singularity = class({})
LinkLuaModifier("modifier_singularity", "heroes/enigma/singularity", LUA_MODIFIER_MOTION_NONE)

function singularity:OnSpellStart()
	self.target = self:GetCursorTarget()
	self.target:AddNewModifier(self:GetCaster(), self, "modifier_singularity", {duration = self:GetChannelTime()})
	--self.casterparticles = ParticleManager:CreateParticle("particles/heroes/enigma/singularity.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	StartSoundEvent("Hero_Enigma.Black_Hole", self:GetCaster())
	StartSoundEvent("Hero_Enigma.Black_Hole", self.target)
end

function singularity:OnChannelFinish(interrupted)
	self.target:RemoveModifierByName("modifier_singularity")
	--ParticleManager:DestroyParticle(self.casterparticles, false)
	StopSoundEvent("Hero_Enigma.Black_Hole", self:GetCaster())
	StopSoundEvent("Hero_Enigma.Black_Hole", self.target)
	if not interrupted then
		ParticleManager:CreateParticle("particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_ti_5.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
		StartSoundEvent("Hero_Enigma.Black_Hole.Stop", self:GetCaster())
		StartSoundEvent("Hero_Antimage.ManaVoid", self.target)
		self.target:Kill(self, self:GetCaster())
	end
end

function singularity:GetChannelAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

-----

modifier_singularity = class({})

function modifier_singularity:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_singularity:OnAttackLanded(info)
	if not IsServer() then return end

	if info.target == self.caster and info.attacker == self.parent then
		self.caster:Interrupt()
	end
end

function modifier_singularity:GetEffectName()
	return "particles/heroes/enigma/singularity.vpcf"
end

function modifier_singularity:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_singularity:OnCreated()
	self.tick_time = 0.25
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.parent = self:GetParent()
	if IsServer() then
		self:StartIntervalThink(self.tick_time)
	end
end

function modifier_singularity:OnIntervalThink()
	-- Check for vision
	if not self.caster:CanEntityBeSeenByMyTeam(self.parent) then
		self.caster:Interrupt()
	end
end