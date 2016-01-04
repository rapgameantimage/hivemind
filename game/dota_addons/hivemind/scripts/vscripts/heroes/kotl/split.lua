split_kotl = class({})

function split_kotl:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_kotl:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_kotl:OnSpellStart()
	GameMode:SplitHero(self)
end