item_bkb_fragment = class({})

function item_bkb_fragment:OnSpellStart()
	local caster = self:GetCaster()
	if caster:GetUnitLabel() == "split_unit" then
		local units = GameMode:GetSplitUnitsForHero(caster:GetPlayerOwner():GetAssignedHero())
		for k,unit in pairs(units) do
			unit:AddNewModifier(caster, self, "modifier_black_king_bar_immune", {duration = self:GetSpecialValueFor("duration")})
		end
	else
		caster:AddNewModifier(caster, self, "modifier_black_king_bar_immune", {duration = self:GetSpecialValueFor("duration")})
	end
	caster:EmitSound("DOTA_Item.BlackKingBar.Activate")
	self:Destroy()
end