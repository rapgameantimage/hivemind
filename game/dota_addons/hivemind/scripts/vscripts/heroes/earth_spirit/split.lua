split_earth_spirit = class({})

function split_earth_spirit:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_earth_spirit:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_earth_spirit:OnSpellStart()
	GameMode:SplitHero(self, Dynamic_Wrap(self, "OnSplitComplete"))
end

function split_earth_spirit:OnSplitComplete(ability)
	if ability then
		self = ability
	end
	local units = GameMode:GetSplitUnitsForHero(self:GetCaster())
	for k,unit in pairs(units) do
		unit:FindAbilityByName("heavyweight"):OnSplitComplete()
	end
	self:GetCaster():EmitSound("Hero_EarthShaker.EchoSlamSmall")
end