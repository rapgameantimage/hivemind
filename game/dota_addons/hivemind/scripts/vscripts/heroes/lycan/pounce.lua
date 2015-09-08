lycan_pounce = class({})

-- Function based on Pizzalol's methodology, but with some improvements to account for changing elevations, terrain, etc.
-- https://github.com/Pizzalol/SpellLibrary/blob/SpellLibrary/game/dota_addons/spelllibrary/scripts/vscripts/heroes/hero_mirana/leap.lua
function lycan_pounce:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local distance = ability:GetSpecialValueFor("distance")
	local duration = ability:GetSpecialValueFor("travel_time")
	local speed = distance/duration
	local peak_height = ability:GetSpecialValueFor("peak_height")

	-- Clears any current command
	caster:Stop()
	caster:StartGesture(ACT_DOTA_ATTACK)

	-- Physics
	local direction = caster:GetForwardVector()
	local time_elapsed = 0

	Physics:Unit(caster)

	local jump = peak_height / duration * .03
	caster:PreventDI(true)
	caster:SetAutoUnstuck(false)
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	caster:FollowNavMesh(false)	
	caster:SetPhysicsVelocity(direction * speed)

	StartSoundEvent("Hero_Slark.Pounce.Cast", caster)

	-- Move the unit
	Timers:CreateTimer(0, function()
		local ground_position = GetGroundPosition(caster:GetAbsOrigin() , caster)
		caster:SetForwardVector(direction)
		time_elapsed = time_elapsed + 0.03
		if time_elapsed < (duration / 2) then
			caster:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,jump)) -- Going up
		else
			-- We can't just use the jump value because we might have changed elevations.
			-- So instead, use how high we are / how much time we have left * tick duration
			local distance_above_ground = (caster:GetAbsOrigin() - GetGroundHeight(caster:GetAbsOrigin(), caster)).z
			local drop = distance_above_ground / (duration - time_elapsed) * 0.03
			caster:SetAbsOrigin(caster:GetAbsOrigin() - Vector(0,0,drop))
		end
		-- If the target reached the ground, or if we're out of time, then remove physics
		if (caster:GetAbsOrigin().z - ground_position.z <= 0) or (time_elapsed >= duration) then
			caster:SetPhysicsAcceleration(Vector(0,0,0))
			caster:SetPhysicsVelocity(Vector(0,0,0))
			caster:OnPhysicsFrame(nil)
			caster:PreventDI(false)
			caster:SetNavCollisionType(PHYSICS_NAV_SLIDE)
			caster:SetAutoUnstuck(true)
			caster:FollowNavMesh(true)
			caster:SetPhysicsFriction(.05)
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false) -- May have got stuck inside of cliffs, trees, etc.

			-- Deal damage and stun to whoever we hit
			local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
			if next(units) ~= nil then
				StartSoundEvent("DOTA_Item.SkullBasher", caster)
				for i,unit in pairs(units) do
					ApplyDamage({
						attacker = caster,
						victim = unit,
						damage_type = self:GetAbilityDamageType(),
						damage = self:GetAbilityDamage(),
						ability = self
					})
					unit:AddNewModifier(caster, self, "modifier_stunned", {duration=self:GetSpecialValueFor("stun")})
				end
			end

			return nil
		end

		return 0.03
	end)
end