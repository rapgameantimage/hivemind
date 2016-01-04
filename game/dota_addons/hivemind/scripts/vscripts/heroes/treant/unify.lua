unify_treant = class({})

function unify_treant:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_treant:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_treant:OnSpellStart()
	GameMode:UnifyHero(self)
end