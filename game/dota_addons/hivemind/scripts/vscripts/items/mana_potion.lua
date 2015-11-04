item_mana_potion = class({})

function item_mana_potion:OnSpellStart()
	local caster = self:GetCaster()
	caster:GiveMana(self:GetSpecialValueFor("mana_amount"))
	caster:EmitSound("DOTA_Item.ClarityPotion.Activate")
	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_chakra_magic.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(p, 1, caster, PATTACH_POINT_FOLLOW, "attach_overhead", caster:GetAbsOrigin(), true)
	self:Destroy()
end