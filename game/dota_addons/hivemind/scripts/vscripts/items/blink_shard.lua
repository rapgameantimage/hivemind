item_blink_shard = class({})

function item_blink_shard:OnSpellStart()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local target = self:GetCursorPosition()
	local blink_range = self:GetSpecialValueFor("blink_range")
	local distance = DistanceBetweenVectors(origin, target)
	if distance > blink_range then
		target = origin + DirectionFromAToB(origin, target) * blink_range * 0.8
	end

	if caster:GetUnitLabel() == "split_unit" then
		local units = GameMode:GetSplitUnitsForHero(caster:GetPlayerOwner():GetAssignedHero())
		for k,unit in pairs(units) do
			if unit ~= caster then
				local relative_vector = unit:GetAbsOrigin() - origin
				ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, unit)
				FindClearSpaceForUnit(unit, target + relative_vector, false)
				ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
			end
		end
	end

	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
	caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
	FindClearSpaceForUnit(caster, target, false)
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
	self:Destroy()
end