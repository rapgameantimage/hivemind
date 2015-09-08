unify_enigma = class({})

function unify_enigma:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_enigma:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_enigma:OnSpellStart()
	GameMode:UnifyHero(self)
end