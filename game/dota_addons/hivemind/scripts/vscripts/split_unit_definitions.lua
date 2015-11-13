-- This file defines what units are created by GameMode:CreateSplitUnits in split_logic.lua

SPLIT_UNIT_NAMES = {
  npc_dota_hero_lycan = "npc_dota_lycan_split_wolf",
  npc_dota_hero_bane = "npc_dota_bane_split_ghost",
  npc_dota_hero_phoenix = "npc_dota_phoenix_split_spirit",
  npc_dota_hero_enigma = "npc_dota_enigma_split_eidolon",
  npc_dota_hero_skeleton_king = "npc_dota_wraith_split_skeleton",
  npc_dota_hero_tinker = "npc_dota_tinker_split_clockwerk",
  npc_dota_hero_earth_spirit = "npc_dota_earth_spirit_split_tiny",
  npc_dota_hero_omniknight = "npc_dota_omniknight_split_angel",
  npc_dota_hero_shadow_demon = "npc_dota_shadow_demon_split_hellhound",
}

NUMBER_OF_SPLIT_UNITS = {
  npc_dota_hero_lycan = 5,
  npc_dota_hero_bane = 5,
  npc_dota_hero_phoenix = 4,
  npc_dota_hero_enigma = 5,
  npc_dota_hero_skeleton_king = 7,
  npc_dota_hero_tinker = 4,
  npc_dota_hero_earth_spirit = 5,
  npc_dota_hero_omniknight = 3,
  npc_dota_hero_shadow_demon = 4,
}

-- Currently not implemented:
SPLIT_UNIT_PARTICLE_FUNCTIONS = {
	npc_dota_hero_phoenix = function(unit)
		p = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_forge_spirit_ambient.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, unit)
  		ParticleManager:SetParticleControlEnt(p, 0, unit, PATTACH_POINT_FOLLOW, "attach_attack1", unit:GetAbsOrigin(), true)
	end,
}

-- Push this information to a nettable so that Panorama can find it later when generating the pick screen.
for hero,unit in pairs(SPLIT_UNIT_NAMES) do
  local t = {}
  t.split_unit_name = unit
  t.split_unit_count = NUMBER_OF_SPLIT_UNITS[hero]
  CustomNetTables:SetTableValue("unit_info", hero, t)
end