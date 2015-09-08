bane_nightmare_orb = class({})
LinkLuaModifier("modifier_nightmare_orb_thinker", "heroes/bane/modifier_nightmare_orb_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nightmare_orb_pull", "heroes/bane/modifier_nightmare_orb_pull", LUA_MODIFIER_MOTION_NONE)

function bane_nightmare_orb:OnSpellStart()
	self.orb = CreateUnitByName("npc_dota_nightmare_orb", self:GetCursorPosition(), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeam())
	StartSoundEvent("Bane.NightmareOrbWhispering", self.orb)
end

function bane_nightmare_orb:OnChannelFinish(interrupted)
	if not self.orb:IsNull() then
		StopSoundEvent("Bane.NightmareOrbWhispering", self.orb)
		StartSoundEvent("Hero_Bane.Nightmare.End", self.orb)
		self.orb:Destroy()
	end
end

function bane_nightmare_orb:GetChannelAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_4
end

function bane_nightmare_orb:CastFilterResultLocation(loc)
	if not IsServer() then return end
	if DistanceBetweenVectors(self:GetCaster():GetAbsOrigin(), loc) < self:GetSpecialValueFor("min_range") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function bane_nightmare_orb:GetCustomCastErrorLocation(loc)
	return "#dota_hud_error_min_range"
end