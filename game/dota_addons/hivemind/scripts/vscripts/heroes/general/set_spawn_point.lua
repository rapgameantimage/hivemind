set_spawn_point = class({})
LinkLuaModifier("modifier_split_move_counter", "heroes/general/modifier_split_move_counter", LUA_MODIFIER_MOTION_NONE)

function set_spawn_point:OnSpellStart()
	local caster = self:GetCaster()
	local units = CustomNetTables:GetTableValue("split_units", tostring(caster:GetEntityIndex()))
	-- Loop through units until we find one that hasn't been moved.
	-- Or, if they've all been moved, take one that's been moved the fewest times.
	local least_moves = -1
	local least_moved_unit = nil
	local unit_to_move = nil
	for unit,info in pairs(units) do
		unit = EntIndexToHScript(tonumber(unit))
		if not unit:HasModifier("modifier_split_move_counter") then
			unit_to_move = unit
			unit_to_move:AddNewModifier(caster, self, "modifier_split_move_counter", {})
			break
		else
			local moves = unit:FindModifierByName("modifier_split_move_counter"):GetStackCount()
			if least_moves == -1 or moves < least_moves then
				least_moves = moves
				least_moved_unit = unit
			end
		end
	end
	if unit_to_move == nil then
		unit_to_move = least_moved_unit
	end
	unit_to_move:FindModifierByName("modifier_split_move_counter"):IncrementStackCount()
	unit_to_move:SetAbsOrigin(self:GetCursorPosition())
end