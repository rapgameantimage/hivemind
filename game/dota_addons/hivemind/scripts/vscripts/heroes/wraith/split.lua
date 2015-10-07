split_wraith = class({})

function split_wraith:CastFilterResult()
	if not IsServer() then return end
	return GameMode:SplitHeroCastFilterResult(self)
end

function split_wraith:GetCustomCastError()
	return GameMode:SplitHeroGetCustomCastError(self)
end

function split_wraith:OnSpellStart()
	if RandomInt(1, 100) == 1 then
		EmitSoundOnClient("Mr_Skeltal.Doot_Doot", self:GetCaster():GetPlayerOwner())
	end
	GameMode:SplitHero(self)
end