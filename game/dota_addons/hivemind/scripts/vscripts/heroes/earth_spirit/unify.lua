unify_earth_spirit = class({})

function unify_earth_spirit:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_earth_spirit:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_earth_spirit:OnSpellStart()
	GameMode:UnifyHero(self)
end