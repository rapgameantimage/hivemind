confusion_hex = class({})

function confusion_hex:OnSpellStart()
	local caster = self:GetCaster()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/neutral_fx/satyr_hellcaller.vpcf",
		vSpawnOrigin = caster:GetOrigin(),
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
	caster:EmitSound("n_creep_SatyrHellcaller.Shockwave")
end

function confusion_hex:OnProjectileHit(target, loc)
	local caster = self:GetCaster()
	local mastery = caster:FindAbilityByName("curse_mastery")
	local mastery_modifier = caster:FindModifierByName("modifier_curse_mastery")
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_confusion", {duration = self:GetSpecialValueFor("duration")})
		mastery:Cascade(self, target)
		return true
	else
		self:GetCaster():FindAbilityByName("curse_mastery"):Miss()
	end
end

---

confusion_hex_cascade = class({})

function confusion_hex_cascade:OnProjectileHit(target, loc)
	local caster = self:GetCaster()
	local confusion_hex = caster:FindAbilityByName("confusion_hex")
	target:AddNewModifier(caster, confusion_hex, "modifier_confusion", {duration = confusion_hex:GetSpecialValueFor("duration")})
	ApplyDamage({
		victim = target,
		attacker = caster,
		ability = confusion_hex,
		damage = caster:FindModifierByName("modifier_curse_mastery"):GetStackCount() * caster:FindAbilityByName("curse_mastery"):GetSpecialValueFor("cascade_target_damage_per_stack"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end

function confusion_hex_cascade:GetParticleName()
	return "particles/units/heroes/hero_dazzle/dazzle_base_attack.vpcf"
end

---

LinkLuaModifier("modifier_confusion", "heroes/shadow_demon/confusion_hex", LUA_MODIFIER_MOTION_NONE)
modifier_confusion = class({})

function modifier_confusion:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.last_origin = self.parent:GetAbsOrigin()
	self.movement = 0
	self.movement_threshold = self:GetAbility():GetSpecialValueFor("movement_threshold")
	self.stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")
	self:StartIntervalThink(0.25)
end

function modifier_confusion:OnIntervalThink()
	local origin = self.parent:GetAbsOrigin()
	self.movement = self.movement + DistanceBetweenVectors(origin, self.last_origin)
	if self.movement >= self.movement_threshold then
		self.parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_confusion_stun", {duration = self.stun_duration})
		self.movement = 0
		self.parent:EmitSound("Hero_Puck.Dream_Coil_Snap")
	end
	self.last_origin = origin
end

function modifier_confusion:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_confusion:IsDebuff()
	return true
end

function modifier_confusion:IsPurgable()
	return true
end

function modifier_confusion:OnDestroy()
	if not IsServer() then return end
end

function modifier_confusion:GetEffectName()
	return "particles/heroes/shadow_demon/confused.vpcf"
end

function modifier_confusion:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

---

LinkLuaModifier("modifier_confusion_stun", "heroes/shadow_demon/confusion_hex", LUA_MODIFIER_MOTION_NONE)
modifier_confusion_stun = class({})

function modifier_confusion_stun:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_confusion_stun:IsDebuff()
	return true
end

function modifier_confusion_stun:IsStunDebuff()
	return true
end

function modifier_confusion_stun:IsPurgable()
	return true
end

function modifier_confusion_stun:GetStatusEffectName()
	return "particles/status_fx/status_effect_enchantress_untouchable.vpcf"
end

function modifier_confusion_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_confusion_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_confusion_stun:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_confusion_stun:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end