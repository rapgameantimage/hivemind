split_phoenix = class({})

function split_phoenix:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_phoenix:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_phoenix:OnSpellStart()
	GameMode:SplitHero(self)
end