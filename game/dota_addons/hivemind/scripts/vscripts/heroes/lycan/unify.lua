unify_lycan = class({})

function unify_lycan:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_lycan:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_lycan:OnSpellStart()
	GameMode:UnifyHero(self)
end