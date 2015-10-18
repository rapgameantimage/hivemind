unify_tinker = class({})

function unify_tinker:CastFilterResult()
	if not IsServer() then return end
	return GameMode:UnifyHeroCastFilterResult(self)
end

function unify_tinker:GetCustomCastError()
	return GameMode:UnifyHeroGetCustomCastError(self)
end

function unify_tinker:OnSpellStart()
	GameMode:UnifyHero(self)
end