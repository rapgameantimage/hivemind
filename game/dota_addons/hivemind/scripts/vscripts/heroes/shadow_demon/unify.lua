unify_shadow_demon = class({})

function unify_shadow_demon:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_shadow_demon:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_shadow_demon:OnSpellStart()
	GameMode:UnifyHero(self)
end