split_enigma = class({})

function split_enigma:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_enigma:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_enigma:OnSpellStart()
	GameMode:SplitHero(self)
end