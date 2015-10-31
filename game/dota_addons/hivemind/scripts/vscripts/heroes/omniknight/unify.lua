unify_omniknight = class({})

function unify_omniknight:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_omniknight:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_omniknight:OnSpellStart()
	GameMode:UnifyHero(self)
end