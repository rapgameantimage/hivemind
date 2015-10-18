split_tinker = class({})

function split_tinker:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_tinker:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_tinker:OnSpellStart()
	GameMode:SplitHero(self)
end