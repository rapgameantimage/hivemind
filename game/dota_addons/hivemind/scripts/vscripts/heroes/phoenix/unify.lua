unify_phoenix = class({})

function unify_phoenix:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_phoenix:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_phoenix:OnSpellStart()
	GameMode:UnifyHero(self)
end