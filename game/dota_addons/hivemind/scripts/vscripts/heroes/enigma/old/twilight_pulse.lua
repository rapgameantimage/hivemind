twilight_pulse = class({})
LinkLuaModifier("modifier_twilight_pulse_passive", "heroes/enigma/modifier_twilight_pulse_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_twilight_pulse_thinker", "heroes/enigma/modifier_twilight_pulse_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_twilight_pulse_immunity", "heroes/enigma/modifier_twilight_pulse_thinker", LUA_MODIFIER_MOTION_NONE)

function twilight_pulse:GetIntrinsicModifierName()
	return "modifier_twilight_pulse_passive"
end