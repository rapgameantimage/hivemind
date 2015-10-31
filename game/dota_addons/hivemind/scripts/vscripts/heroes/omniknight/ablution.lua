ablution = class({})

function ablution:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ablution", {duration = self:GetSpecialValueFor("duration")})
	self:GetCaster():EmitSound("Hero_Oracle.FalsePromise.Healed")
end

function ablution:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

---

LinkLuaModifier("modifier_ablution", "heroes/omniknight/ablution", LUA_MODIFIER_MOTION_NONE)
modifier_ablution = class({})

function modifier_ablution:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1)
	self:SetStackCount(self:GetAbility():GetSpecialValueFor("attacks_to_dispel"))
end

function modifier_ablution:OnIntervalThink()
	if not self:GetParent():HasModifier("modifier_hidden") then
		self:GetParent():Heal(self:GetAbility():GetSpecialValueFor("heal_per_second"), self:GetAbility():GetCaster())
		self:GetParent():EmitSound("n_creep_ForestTrollHighPriest.Heal")
	end
end

function modifier_ablution:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_ablution:OnAttackLanded(event)
	if event.target == self:GetParent() then
		self:DecrementStackCount()
		if self:GetStackCount() < 1 then
			self:Destroy()
		end
	end
end

function modifier_ablution:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_purifyingflames_heal.vpcf"
end

function modifier_ablution:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end