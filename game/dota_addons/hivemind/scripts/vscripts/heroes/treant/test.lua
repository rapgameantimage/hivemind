ethereal_forest = class({})

function ethereal_forest:OnSpellStart()
	local tree = CreateUnitByName("ethereal_tree", self:GetCursorPosition(), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeam())
	tree:AddNewModifier(self:GetCaster(), self, "modifier_item_ghost_scepter", {})
end