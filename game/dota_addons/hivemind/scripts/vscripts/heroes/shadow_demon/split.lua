split_shadow_demon = class({})

function split_shadow_demon:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_shadow_demon:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_shadow_demon:OnSpellStart()
	GameMode:SplitHero(self)
end