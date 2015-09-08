freezing_wind = class({})
LinkLuaModifier("modifier_freezing_wind", "heroes/phoenix/modifier_freezing_wind", LUA_MODIFIER_MOTION_NONE)

function freezing_wind:OnSpellStart()
	self.slow_duration = self:GetSpecialValueFor("duration")
	self.caster = self:GetCaster()
	self.direction = ((self:GetCursorPosition() - self.caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	self.velocity = self.direction * self:GetSpecialValueFor("projectile_speed")
	self.eggs_being_dragged = {}
	local proj = ({
		Ability = self,
		EffectName = "particles/units/heroes/hero_drow/drow_silence_wave.vpcf",
		vSpawnOrigin = self.caster:GetAbsOrigin(),
		vVelocity = self.velocity,
		fDistance = self:GetSpecialValueFor("projectile_distance"),
		fStartRadius = self:GetSpecialValueFor("projectile_radius"),
		fEndRadius = self:GetSpecialValueFor("projectile_radius"),
		Source = self.caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH, -- Needed to hit eggs
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	})
	ProjectileManager:CreateLinearProjectile(proj)
	StartSoundEvent("Hero_DrowRanger.Silence", self.caster)
end

function freezing_wind:OnProjectileHit(target, loc)
	if target ~= nil then
		if target:GetTeam() ~= self.caster:GetTeam() then
			if target:HasModifier("modifier_freezing_wind") then
				local mod = target:FindModifierByName("modifier_freezing_wind")
				mod:SetDuration(mod:GetDuration() + self.slow_duration, true)
			else
				target:AddNewModifier(self.caster, self, "modifier_freezing_wind", {duration = self.slow_duration})
			end
		elseif target:GetUnitName() == "npc_dota_fiery_birth_egg" then
			-- Drag the egg with us
			self.eggs_being_dragged[target] = true
			if not IsPhysicsUnit(target) then Physics:Unit(target) end
			target:AddPhysicsVelocity(self.velocity / 2)
		end
	end
end

function freezing_wind:GetCastAnimation()
	return ACT_DOTA_ARCTIC_BURN_END
end