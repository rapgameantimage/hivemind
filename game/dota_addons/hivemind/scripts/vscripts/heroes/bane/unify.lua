unify_bane = class({})

function unify_bane:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_bane:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_bane:OnSpellStart()
	GameMode:UnifyHero(self)
end