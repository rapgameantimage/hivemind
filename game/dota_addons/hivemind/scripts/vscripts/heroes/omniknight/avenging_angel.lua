avenging_angel = class({})

function avenging_angel:CastFilterResult()
	if not IsServer() then return end
	local units = GameMode:GetSplitUnitsForHero(self:GetCaster():GetPlayerOwner():GetAssignedHero())
	local num_units = 0
	for k,unit in pairs(units) do
		num_units = num_units + 1
		if num_units > 1 then
			return UF_FAIL_CUSTOM
		end
	end
	return UF_SUCCESS
end

function avenging_angel:GetCustomCastError()
	return "#dota_hud_error_cant_cast_while_other_split_units_alive"
end

function avenging_angel:OnSpellStart()
	SendToServerConsole( "dota_combine_models 0" )
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_avenging_angel", {duration = self:GetSpecialValueFor("duration")})
	ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
	self:GetCaster():EmitSound("Hero_Terrorblade.Metamorphosis")
	self:GetCaster():EmitSound("vengefulspirit_vng_levelup_02")
	self:SetHidden(true)
end

function avenging_angel:GetCastAnimation()
	return ACT_DOTA_TELEPORT_END
end

---

LinkLuaModifier("modifier_avenging_angel", "heroes/omniknight/avenging_angel", LUA_MODIFIER_MOTION_NONE)
modifier_avenging_angel = class({})

function modifier_avenging_angel:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	if not IsServer() then return end

	self.parent:SetOriginalModel("models/items/terrorblade/endless_purgatory_demon/endless_purgatory_demon.vmdl")
	self.parent:SetRangedProjectileName("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf")
	local slots = CosmeticLib:GetAvailableSlotForHero("npc_dota_hero_skywrath_mage")
	for k,slot in pairs(slots) do
		CosmeticLib:RemoveFromSlot(self.parent, slot)
	end
end

function modifier_avenging_angel:GetEffectName()
	return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf"
end

function modifier_avenging_angel:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

function modifier_avenging_angel:DeclareFunctions()
	return {MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT}
end

function modifier_avenging_angel:GetModifierBaseDamageOutgoing_Percentage()
	return self.ability:GetSpecialValueFor("damage_bonus")
end

function modifier_avenging_angel:GetModifierMoveSpeedBonus_Constant()
	return self.ability:GetSpecialValueFor("movespeed_bonus")
end

function modifier_avenging_angel:OnDestroy()
	if not IsServer() then return end
	self.parent:SetModel("models/heroes/skywrath_mage/skywrath_mage.vmdl")
	self.parent:SetOriginalModel("models/heroes/skywrath_mage/skywrath_mage.vmdl")
	self.parent:SetRangedProjectileName("particles/units/heroes/hero_skywrath_mage/skywrath_mage_base_attack.vpcf")
	CosmeticLib:ReplaceWithSlotName(self.parent, "arms", 8931)
	CosmeticLib:ReplaceWithSlotName(self.parent, "back", 8932)
	CosmeticLib:ReplaceWithSlotName(self.parent, "belt", 8933)
	CosmeticLib:ReplaceWithSlotName(self.parent, "head", 8934)
	CosmeticLib:ReplaceWithSlotName(self.parent, "shoulder", 8936)
	CosmeticLib:ReplaceWithSlotName(self.parent, "weapon", 8937)
	self.parent:RemoveGesture(ACT_DOTA_DIE)
	StartAnimation(self.parent, {activity = ACT_DOTA_SPAWN, duration = .5})
	self.parent:EmitSound("Hero_Terrorblade.Metamorphosis")
end