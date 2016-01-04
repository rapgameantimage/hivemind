unify_kotl = class({})

function unify_kotl:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_kotl:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_kotl:OnSpellStart()
	GameMode:UnifyHero(self)
end