lycan_hamstring = class({})
LinkLuaModifier("modifier_hamstring", "heroes/lycan/modifier_hamstring", LUA_MODIFIER_MOTION_NONE)

function lycan_hamstring:OnAbilityPhaseStart()
  self:GetCaster():RemoveGesture(ACT_DOTA_ATTACK)
  return true
end

function lycan_hamstring:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  
  ApplyDamage({
    victim = target,
    attacker = caster,
    damage = self:GetAbilityDamage(),
    damage_type = self:GetAbilityDamageType(),
    ability = self
  })
  
  target:AddNewModifier(caster, self, "modifier_hamstring", {duration = self:GetSpecialValueFor("duration")})
  
  ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_open_wounds_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
  StartSoundEvent("DOTA_Item.Maim", target)
end

function lycan_hamstring:GetCastAnimation()
  return ACT_DOTA_CAST_ABILITY_1
end

function lycan_hamstring:GetPlaybackRateOverride()
  return 1.5
end
