item_enchanted_skull = class({})

function item_enchanted_skull:OnSpellStart()
	local caster = self:GetCaster()
	local hero
	local unitname
	if caster:GetUnitLabel() == "split_unit" then
		unitname = caster:GetUnitName()
		hero = caster:GetPlayerOwner():GetAssignedHero()
	else
		unitname = SPLIT_UNIT_NAMES[caster:GetName()]
		hero = caster
	end
	local unit = CreateUnitByName(unitname, caster:GetAbsOrigin(), true, hero, hero, hero:GetTeam())
	unit:SetControllableByPlayer(hero:GetPlayerOwnerID(), true)
	if hero == caster then
		unit:AddNewModifier(caster, nil, "modifier_hidden", {})
		ParticleManager:CreateParticle("particles/econ/events/ti4/blink_dagger_start_ti4.vpcf", PATTACH_ABSORIGIN, hero)
	else
		ParticleManager:CreateParticle("particles/econ/events/ti4/blink_dagger_start_ti4.vpcf", PATTACH_ABSORIGIN, unit)
	end

	local split_unit_table = CustomNetTables:GetTableValue("split_units", tostring(hero:GetEntityIndex()))
	largest_id = 0
	for unit,info in pairs(split_unit_table) do
		if tonumber(info.id) > largest_id then
			largest_id = info.id
		end
	end
	split_unit_table[tostring(unit:GetEntityIndex())] = {id = largest_id + 1, unitname = unitname}
	CustomNetTables:SetTableValue("split_units", tostring(hero:GetEntityIndex()), split_unit_table)
	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "split_units_created", {these_values = "arent_used_anyway"})
	caster:EmitSound("Hero_SkywrathMage.MysticFlare.Cast")
	self:Destroy()
end