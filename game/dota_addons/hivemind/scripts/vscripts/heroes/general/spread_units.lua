spread_units = class({})

function spread_units:OnSpellStart()
	local spread_distance = 100

	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_spread_count", {duration = SPLIT_DELAY})
	local center = caster:GetAbsOrigin()
	local units = GameMode:GetSplitUnitsForHero(caster)
	for k,unit in pairs(units) do
		local unit_origin = unit:GetAbsOrigin()
		local direction = DirectionFromAToB(center, unit_origin)
		local desired_position = unit_origin + (direction * spread_distance)
		unit:SetAbsOrigin(Arena:MoveLocationWithinBounds(desired_position))
	end
end

function spread_units:CastFilterResult()
	local max_spreads = 3

	local caster = self:GetCaster()
	if caster:HasModifier("modifier_spread_count") then
		if caster:GetModifierStackCount("modifier_spread_count", caster) >= max_spreads then
			return UF_FAIL_CUSTOM
		end
	end

	return UF_SUCCESS
end

function spread_units:GetCustomCastError()
	return "#dota_hud_error_max_spread_distance"
end

---

LinkLuaModifier("modifier_spread_count", "heroes/general/spread_units", LUA_MODIFIER_MOTION_NONE)
modifier_spread_count = class({})

function modifier_spread_count:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(1)
end

function modifier_spread_count:OnRefresh()
	if not IsServer() then return end
	self:IncrementStackCount()
end

function modifier_spread_count:IsHidden()
	return true
end