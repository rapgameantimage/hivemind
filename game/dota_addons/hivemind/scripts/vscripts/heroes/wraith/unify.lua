unify_wraith = class({})

function unify_wraith:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_wraith:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_wraith:OnSpellStart()
	GameMode:UnifyHero(self)
end