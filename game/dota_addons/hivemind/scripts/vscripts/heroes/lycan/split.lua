split_lycan = class({})

function split_lycan:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_lycan:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_lycan:OnSpellStart()
	GameMode:SplitHero(self)
end