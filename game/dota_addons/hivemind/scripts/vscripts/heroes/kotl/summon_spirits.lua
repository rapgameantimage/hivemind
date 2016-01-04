summon_spirits = class({})

function summon_spirits:OnSpellStart()
	self.i = 0
	if not self.spirits then
		self.spirits = {}
	end
end

function summon_spirits:OnChannelThink(interval)
	self.i = self.i + 1
	if self.i >= 3 then
		local mod = self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName())
		if mod:GetStackCount() < self:GetSpecialValueFor("max_spirits") then
			if not mod.center then
				mod.center = CreateModifierThinker(self:GetCaster(), self, "modifier_spirits_center", {}, self:GetCaster():GetAbsOrigin(), self:GetCaster():GetTeam(), false)
			end
			local loc = mod.center:GetAbsOrigin() + RandomVector(1000)
			local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_guardian_.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
			ParticleManager:SetParticleControl(pfx, 0, loc)
			self.spirits[DoUniqueString("kotl_spirit")] = {loc = loc, pfx = pfx, variance = 0, variance_remaining = 0}
			mod:IncrementStackCount()
		else
			self:GetCaster():Interrupt()
		end
		self.i = 0
	end
end

function summon_spirits:OnChannelFinish(interrupted)
	self.i = 0
end

function summon_spirits:GetIntrinsicModifierName()
	return "modifier_summon_spirits"
end

function summon_spirits:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

function summon_spirits:CastFilterResult()
	if not IsServer() then return end
	if self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName()):GetStackCount() >= self:GetSpecialValueFor("max_spirits") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function summon_spirits:GetCustomCastError()
	return "#dota_hud_error_max_spirits_reached"
end

function summon_spirits:SpendSpirits(num)
	local i = 0
	local mod = self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName())
	if not self.spirits then return end
	for k,spirit in pairs(self.spirits) do
		ParticleManager:DestroyParticle(spirit.pfx, false)
		self.spirits[k] = nil
		if mod then
			mod:DecrementStackCount()
		end
		i = i + 1
		if i >= num then
			break
		end
	end
end

---

LinkLuaModifier("modifier_summon_spirits", "heroes/kotl/summon_spirits", LUA_MODIFIER_MOTION_NONE)
modifier_summon_spirits = class({})

function modifier_summon_spirits:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_summon_spirits:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.inner = self.ability:GetSpecialValueFor("inner_radius")
	self.outer = self.ability:GetSpecialValueFor("outer_radius")
	self.tick = 0
	self:StartIntervalThink(0.03)
end

function modifier_summon_spirits:OnIntervalThink()
	self.tick = self.tick + 1
	local spirits = self:GetAbility().spirits
	local center
	if self.center then
		if self.center:IsNull() then
			self.center = nil
			return
		else
			center = self.center:GetAbsOrigin()
		end
	end

	if spirits and center then
		for k,info in pairs(spirits) do
			local oldloc = info.loc
			-- Rotate position of this spirit a small amount (slighly random, but 1 degree on average) clockwise around self.center.
    		local newloc = RotatePosition(center, QAngle(0, RandomFloat(0.9, 1.1), 0), oldloc)
    		-- We might have gone uphill or downhill
    		newloc = GetGroundPosition(newloc, nil)

    		-- "Variance" is the outward/inward amount by which the spirit's position is offset each tick.
    		-- So with a variance of 5, the spirit moves 5 units away from the center per tick. With -5, it moves 5 units towards the center.
    		-- We only change variance every few ticks so that this movement appears smooth and wavering instead of jerky.
    		-- We use variance_remaining to keep track of how many more ticks we have to go before changing this spirit's variance.
    		if info.variance_remaining == 0 then
    			-- If the spirit is nearing the inner or outer edges of the ring, we want to use variance to force it outwards or inwards.
    			-- Without this, the spirits have a tendency to get "stuck" at the inner and outer edges.
    			local distance = DistanceBetweenVectors(newloc, center)
    			if distance > self.outer - 50 then
    				info.variance = info.variance + RandomFloat(-10, 0)
    			elseif distance < self.inner + 50 then
    				info.variance = info.variance + RandomFloat(0, 10)
    			else
    				info.variance = info.variance + RandomFloat(-5, 5)
    			end
    			-- Now we pick a random number of ticks for this particular variance to last.
    			info.variance_remaining = RandomInt(3,7)
    		else
    			info.variance_remaining = info.variance_remaining - 1
    		end
	    	newloc = newloc + DirectionFromAToB(center, newloc) * info.variance

	    	-- If the spirit's new position would be outside the bounds, move it inside.
	    	if DistanceBetweenVectors(newloc, center) < self.inner then
	    		newloc = center + DirectionFromAToB(center, newloc) * self.inner
	    	elseif DistanceBetweenVectors(newloc, center) > self.outer then
	    		newloc = center + DirectionFromAToB(center, newloc) * self.outer
	    	end

	    	-- Move the particle, then store the new position in our table.
			ParticleManager:SetParticleControl(info.pfx, 0, newloc)
			spirits[k].loc = newloc

			-- Check collision only every few ticks, to help with performance
			if self.tick % 6 == 0 then
				local units = FindUnitsInRadius(self:GetParent():GetTeam(), newloc, nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
				if units then
					for j,unit in pairs(units) do
						ApplyDamage({
							attacker = self:GetParent(),
							victim = unit,
							ability = self:GetAbility(),
							damage = self:GetAbility():GetSpecialValueFor("spirit_damage"),
							damage_type = DAMAGE_TYPE_MAGICAL,
						})
						local explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_guardian_explosion.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
						ParticleManager:SetParticleControl(explosion, 0, newloc)
						ParticleManager:DestroyParticle(info.pfx, false)
						spirits[k] = nil
						self:DecrementStackCount()

						if self:GetStackCount() == 0 then
							self.center:Destroy()
							self.center = nil
						end
					end
				end
			end
		end
	end
end

function modifier_summon_spirits:OnDestroy()
	if not IsServer() then return end
	self:GetAbility():SpendSpirits(self:GetStackCount())
	if self.center then
		if not self.center:IsNull() then
			self.center:Destroy()
		end
		self.center = nil
	end
end

function modifier_summon_spirits:RemoveOnDeath()
	return true
end

function modifier_summon_spirits:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH, MODIFIER_EVENT_ON_RESPAWN}
end

function modifier_summon_spirits:OnDeath(info)
	if info.unit == self:GetParent() then
		self:OnDestroy()
	end
end

function modifier_summon_spirits:OnRespawn(info)
	if info.unit == self:GetParent() then
		self:OnDestroy()
	end
end

---

LinkLuaModifier("modifier_spirits_center", "heroes/kotl/summon_spirits", LUA_MODIFIER_MOTION_NONE)
modifier_spirits_center = class({})

function modifier_spirits_center:GetEffectName()
	return "particles/heroes/kotl/spirits_center_marker.vpcf"
end

function modifier_spirits_center:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end