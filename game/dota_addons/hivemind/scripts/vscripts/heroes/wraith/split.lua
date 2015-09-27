split_wraith = class({})

function split_wraith:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_wraith:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_wraith:OnSpellStart()
	GameMode:SplitHero(self)
end