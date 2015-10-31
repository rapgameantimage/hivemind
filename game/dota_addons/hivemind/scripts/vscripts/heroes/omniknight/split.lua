split_omniknight = class({})

function split_omniknight:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_omniknight:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_omniknight:OnSpellStart()
	GameMode:SplitHero(self)
end