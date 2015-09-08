modifier_hamstring = class({})

function modifier_hamstring:DeclareFunctions()
  return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_hamstring:IsDebuff()
  return true
end

function modifier_hamstring:IsPurgable()
  return true
end

function modifier_hamstring:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("slow") * -1
end
  
function modifier_hamstring:GetEffectName()
  return "particles/items2_fx/sange_maim.vpcf"
end

function modifier_hamstring:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_hamstring:CheckState()
	if IsServer() then
		if self:GetParent():HasModifier("modifier_lacerate") then
			if self:GetParent():FindModifierByName("modifier_lacerate"):GetStackCount() >= 3 then
				return { [MODIFIER_STATE_ROOTED] = true, }
			end
		end
	end
end