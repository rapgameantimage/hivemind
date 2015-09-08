split_bane = class({})

function split_bane:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_bane:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_bane:OnSpellStart()
	GameMode:SplitHero(self)
end