distant_malice = class({})

function distant_malice:GetIntrinsicModifierName()
	return "modifier_distant_malice_passive"
end

-----

LinkLuaModifier("modifier_distant_malice_passive", "heroes/enigma/distant_malice", LUA_MODIFIER_MOTION_NONE)
modifier_distant_malice_passive = class({})

function modifier_distant_malice_passive:IsHidden()
	return true
end

function modifier_distant_malice_passive:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_distant_malice_passive:OnAttackLanded(info)
	if not IsServer() then return end

	local ability = self:GetAbility()
	if info.attacker == self:GetParent() and ability:IsCooldownReady() and not info.target:IsMagicImmune() then
		if not info.target:HasModifier("modifier_distant_malice") then
			info.target:AddNewModifier(self:GetParent(), ability, "modifier_distant_malice", {duration = ability:GetSpecialValueFor("delay")})
		else
			info.target:FindModifierByName("modifier_distant_malice"):AddNewInstance(self:GetParent())
		end
		ability:StartCooldown(ability:GetCooldown(1))
	end
end

-----

LinkLuaModifier("modifier_distant_malice", "heroes/enigma/distant_malice", LUA_MODIFIER_MOTION_NONE)
modifier_distant_malice = class({})

function modifier_distant_malice:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.team = self.ability:GetCaster():GetTeam()
	self.stun_time = self.ability:GetSpecialValueFor("stun_time")
	self.damage = self.ability:GetAbilityDamage()
	self.damage_type = self.ability:GetAbilityDamageType()
	self.tick_time = 0.03
	self.delay = self.ability:GetSpecialValueFor("delay")
	self.phase = 1
	self.timings = {}
	self:AddNewInstance(self.ability:GetCaster())

	self:SetStackCount(1)

	-- We'll start checking this every tick later, but there's no need to do that until self.delay has elapsed, since by definition it's impossible for a stun to proc before then.
	self:StartIntervalThink(self.delay - 0.03)
end

function modifier_distant_malice:AddNewInstance(caster)
	self.timings[DoUniqueString("distant_malice")] = {time = GameRules:GetGameTime() + self.delay, caster = caster}
	self:SetDuration(self.delay, true)
	self:IncrementStackCount()
end

function modifier_distant_malice:OnIntervalThink()
	for key,info in pairs(self.timings) do
		if GameRules:GetGameTime() >= info.time then
			if info.caster:IsNull() then
				-- beep beep garbage truck was here
				info.caster = CreateModifierThinker(nil, self.ability, "modifier_postmortem_damage_source", {duration = 0.03}, self.parent:GetAbsOrigin(), self.team, false)
			end
			local dmg = ({
				victim = self.parent,
				attacker = info.caster,
				damage = self.damage,
				damage_type = self.damage_type,
				ability = self.ability,
			})
			ApplyDamage(dmg)
			self.parent:AddNewModifier(info.caster, self.ability, "modifier_distant_malice_stun", {duration = self.stun_time})
			self.timings[key] = nil
			self:DecrementStackCount()
		end
	end
	if self.phase == 1 then
		self.phase = 2
		self:StartIntervalThink(self.tick_time)
	end
end

function modifier_distant_malice:IsDebuff()
	return true 
end

function modifier_distant_malice:GetEffectName()
	return "particles/units/heroes/hero_enigma/enigma_malefice.vpcf"
end

function modifier_distant_malice:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

-----

LinkLuaModifier("modifier_distant_malice_stun", "heroes/enigma/distant_malice", LUA_MODIFIER_MOTION_NONE)
modifier_distant_malice_stun = class({})

function modifier_distant_malice_stun:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_distant_malice_stun:IsStunDebuff()
	return true
end

function modifier_distant_malice_stun:IsDebuff()
	return true
end

function modifier_distant_malice_stun:GetStatusEffectName()
	return "particles/status_fx/status_effect_enigma_malefice.vpcf"
end

function modifier_distant_malice_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_distant_malice_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_distant_malice_stun:OnCreated()
	if not IsServer() then return end
	StartSoundEvent("Hero_Enigma.Malefice", self:GetParent())
end