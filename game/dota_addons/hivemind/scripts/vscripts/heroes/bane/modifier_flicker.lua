modifier_flicker = class({})

function modifier_flicker:OnCreated()
	if not IsServer() then return end

	self.interval = 0
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("interval"))
end

function modifier_flicker:OnIntervalThink()
	if not IsServer() then return end

	local caster = self:GetAbility():GetCaster()
	self.interval = self.interval + 1
	if self.interval % 2 == 1 then
		StartSoundEvent("DOTA_Item.InvisibilitySword.Activate", caster)
		caster:AddNewModifier(caster, self:GetAbility(), "modifier_flicker_invis", {duration = self:GetAbility():GetSpecialValueFor("interval")})
		-- Not sure how else to apply the translucent texture other than this way:
		caster:AddNewModifier(caster, self:GetAbility(), "modifier_invisible", {duration = self:GetAbility():GetSpecialValueFor("interval")})
	else
		if caster:HasModifier("modifier_flicker_invis") then
			caster:RemoveModifierByName("modifier_flicker_invis")
			caster:RemoveModifierByName("modifier_invisible")
		end
	end
end

function modifier_flicker:IsPurgable()
	return true
end