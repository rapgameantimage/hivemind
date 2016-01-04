split_treant = class({})

function split_treant:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_treant:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_treant:OnSpellStart()
	GameMode:SplitHero(self)
end