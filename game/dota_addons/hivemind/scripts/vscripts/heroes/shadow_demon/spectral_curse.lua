spectral_curse = class({})

function spectral_curse:OnSpellStart()
	local caster = self:GetCaster()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_projectile.vpcf",
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
	caster:EmitSound("Hero_ShadowDemon.ShadowPoison")
end

function spectral_curse:OnProjectileHit(target, loc)
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_spectral_curse", {duration = self:GetSpecialValueFor("duration")})
		self:GetCaster():FindAbilityByName("curse_mastery"):Cascade(self, target)
		target:EmitSound("Hero_ShadowDemon.ShadowPoison.Impact")
		return true
	else
		self:GetCaster():FindAbilityByName("curse_mastery"):Miss()
	end
end

function spectral_curse:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

---

spectral_curse_cascade = class({})

function spectral_curse_cascade:OnProjectileHit(target, loc)
	local caster = self:GetCaster()
	local curse = caster:FindAbilityByName("spectral_curse")
	target:AddNewModifier(caster, curse, "modifier_spectral_curse", {duration = curse:GetSpecialValueFor("duration")})
	caster:FindAbilityByName("curse_mastery"):CascadeDamage(self, target)
end

function spectral_curse_cascade:GetParticleName()
	return "particles/units/heroes/hero_shadow_demon/shadow_demon_base_attack.vpcf"
end

---

LinkLuaModifier("modifier_spectral_curse", "heroes/shadow_demon/spectral_curse", LUA_MODIFIER_MOTION_NONE)
modifier_spectral_curse = class({})

function modifier_spectral_curse:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:StartIntervalThink(self.ability:GetSpecialValueFor("tick_interval"))
end

function modifier_spectral_curse:OnIntervalThink()
	if not self.parent:HasModifier("modifier_hidden") then
		CustomNetTables:SetTableValue("gamestate", "dont_create_split_units", {["1"] = "1"})
		local illusion = CreateUnitByName(self.parent:GetUnitName(), self.parent:GetAbsOrigin() + self.parent:GetForwardVector() * 80, false, self.ability:GetCaster(), nil, self.ability:GetCaster():GetTeam())
		CustomNetTables:SetTableValue("gamestate", "dont_create_split_units", {})
		illusion:AddNewModifier(self.ability:GetCaster(), self.ability, "modifier_illusion", {outgoing_damage = self.ability:GetSpecialValueFor("illusion_outgoing_damage_pct") * -1, incoming_damage = 0})
		illusion:AddNewModifier(self.ability:GetCaster(), self.ability, "modifier_spectral_curse_illusion", {duration = 1})
		illusion:MakeIllusion()
		illusion:SetForwardVector(self.parent:GetForwardVector() * -1)
		illusion:SetForceAttackTarget(self.parent)
	end
end

function modifier_spectral_curse:IsDebuff()
	return true
end

function modifier_spectral_curse:IsPurgable()
	return true
end

---

LinkLuaModifier("modifier_spectral_curse_illusion", "heroes/shadow_demon/spectral_curse", LUA_MODIFIER_MOTION_NONE)
modifier_spectral_curse_illusion = class({})

function modifier_spectral_curse_illusion:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_spectral_curse_illusion:OnAttackLanded(event)
	if event.attacker == self:GetParent() then
		self:Destroy()
	end
end

function modifier_spectral_curse_illusion:OnDestroy()
	if not IsServer() then return end
	self:GetParent():ForceKill(false)
end

function modifier_spectral_curse_illusion:CheckState()
	return {[MODIFIER_STATE_NOT_ON_MINIMAP] = true, [MODIFIER_STATE_UNSELECTABLE] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_INVULNERABLE] = true,}
end