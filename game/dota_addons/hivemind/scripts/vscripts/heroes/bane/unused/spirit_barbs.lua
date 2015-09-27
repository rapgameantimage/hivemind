bane_spirit_barbs = class({})
LinkLuaModifier("modifier_spirit_barbs", "heroes/bane/modifier_spirit_barbs", LUA_MODIFIER_MOTION_NONE)

function bane_spirit_barbs:OnSpellStart()
	local units = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetCursorPosition(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for i,unit in pairs(units) do
		unit:AddNewModifier(self:GetCaster(), self, "modifier_spirit_barbs", {duration = self:GetSpecialValueFor("duration")})
	end
end

function bane_spirit_barbs:GetCastAnimation()
	return ACT_DOTA_ENFEEBLE
end

function bane_spirit_barbs:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

