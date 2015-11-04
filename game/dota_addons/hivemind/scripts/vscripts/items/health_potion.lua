item_health_potion = class({})

function item_health_potion:OnSpellStart()
	local caster = self:GetCaster()
	caster:Heal(self:GetSpecialValueFor("heal_amount"), caster)
	caster:EmitSound("DOTA_Item.HealingSalve.Activate")
	local p = ParticleManager:CreateParticle("particles/frostivus_gameplay/wraith_king_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(p, 3, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	self:Destroy()
end