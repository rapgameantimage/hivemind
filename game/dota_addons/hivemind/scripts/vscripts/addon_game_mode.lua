-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('gamemode')

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode.lua for more information
  ]]

  DebugPrint("[BAREBONES] Performing pre-load precache")

  -- Gamewide resources

  VectorTarget:Precache( context )

  PrecacheResource("particle", "particles/split_count.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)
  PrecacheResource("model", "models/development/invisiblebox.vmdl", context )
  PrecacheResource("particle", "particles/arena_wall.vpcf", context)
  PrecacheResource("particle", "particles/nothing.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_vo_announcer.vsndevts", context)

  -- Possible hero cosmetics (some are non-existent but that's ok)

  PrecacheResource( "model_folder", "models/heroes/lycan", context )
  PrecacheResource( "model_folder", "models/items/lycan", context )
  PrecacheResource( "particle_folder", "particles/econ/items/lycan", context )

  PrecacheResource( "model_folder", "models/heroes/bane", context )
  PrecacheResource( "model_folder", "models/items/bane", context )
  PrecacheResource( "particle_folder", "particles/econ/items/bane", context )

  PrecacheResource( "model_folder", "models/heroes/phoenix", context )
  PrecacheResource( "model_folder", "models/items/phoenix", context )
  PrecacheResource( "particle_folder", "particles/econ/items/phoenix", context )

  PrecacheResource( "model_folder", "models/heroes/enigma", context )
  PrecacheResource( "model_folder", "models/items/enigma", context )
  PrecacheResource( "particle_folder", "particles/econ/items/enigma", context )

  -- yes, both are necessary:
  PrecacheResource( "model_folder", "models/heroes/skeleton_king", context )
  PrecacheResource( "model_folder", "models/items/skeleton_king", context )
  PrecacheResource( "particle_folder", "particles/econ/items/skeleton_king", context )
  PrecacheResource( "model_folder", "models/heroes/wraith_king", context )
  PrecacheResource( "model_folder", "models/items/wraith_king", context )
  PrecacheResource( "particle_folder", "particles/econ/items/wraith_king", context )

  PrecacheResource( "model_folder", "models/heroes/tinker", context )
  PrecacheResource( "model_folder", "models/items/tinker", context )
  PrecacheResource( "particle_folder", "particles/econ/items/tinker", context )

  PrecacheResource( "model_folder", "models/heroes/earth_spirit", context )
  PrecacheResource( "model_folder", "models/items/earth_spirit", context )
  PrecacheResource( "particle_folder", "particles/econ/items/earth_spirit", context )

  PrecacheResource( "model_folder", "models/heroes/omniknight", context )
  PrecacheResource( "model_folder", "models/items/omniknight", context )
  PrecacheResource( "particle_folder", "particles/econ/items/omniknight", context )
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
end