summon_wraith = class({})

function summon_wraith:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	CustomNetTables:SetTableValue("gamestate", "dont_create_split_units", {["1"] = "1"})
	local wraith = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin() + RandomVector(100), false, caster, nil, caster:GetTeam())
	CustomNetTables:SetTableValue("gamestate", "dont_create_split_units", {})
	-- We have to use the entity index to communicate the target because hscript values don't pass properly here
	wraith:AddNewModifier(caster, self, "modifier_wraith", {duration = self:GetSpecialValueFor("wraith_duration"), target = target:GetEntityIndex()})
	-- need both of these or it looks wrong.
	wraith:AddNewModifier(caster, self, "modifier_illusion", {outgoing_damage = self:GetSpecialValueFor("wraith_damage_percent") * -1, incoming_damage = 100})
	wraith:AddNewModifier(caster, self, "modifier_darkseer_wallofreplica_illusion", {})
	wraith:MakeIllusion()
	wraith:SetForceAttackTarget(target)

	caster:SwapAbilities("summon_wraith", "wraith_swap_positions", false, true)

	self:SetIntAttr("wraith_index", wraith:GetEntityIndex())		-- Used to find the wraith later to swap positions with it

	ParticleManager:CreateParticle("particles/generic_gameplay/illusion_created.vpcf", PATTACH_POINT_FOLLOW, wraith)
end

function summon_wraith:OnUpgrade()
	if not IS_SKELETON_KING_PRECACHED then
		PrecacheUnitByNameAsync("npc_dota_hero_skeleton_king", function() IS_SKELETON_KING_PRECACHED = true end)
	end
end

function summon_wraith:GetCastAnimation()
	return ACT_DOTA_TELEPORT
end

---

LinkLuaModifier("modifier_wraith", "heroes/wraith/summon_wraith", LUA_MODIFIER_MOTION_NONE)
modifier_wraith = class({})

function modifier_wraith:OnCreated(info)
	if not IsServer() then return end
	self.target = EntIndexToHScript( info.target )
	self.attacks_landed = 0
	self:OnIntervalThink()
	self:StartIntervalThink(0.03)
	local ice = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_relic_weapon/wraith_king_relic_weapon.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(ice, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), true)
end

function modifier_wraith:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_wraith:OnIntervalThink()
	if not IsServer() then return end

	if not self.target or self.target:IsNull() or not self.target:IsAlive() or self.target:HasModifier("modifier_hidden") then
		self:Destroy()
	end

	-- Spins the wraith around continuously to always be on the opposite side of the target as the real hero
	local direction_from_caster_to_target = DirectionFromAToB(self:GetCaster():GetAbsOrigin(), self.target:GetAbsOrigin())
	local distance_from_wraith_to_target = DistanceBetweenVectors(self:GetParent():GetAbsOrigin(), self.target:GetAbsOrigin())
	if distance_from_wraith_to_target < 130 then
		-- if we're close we can just put ourselves in the right position
		self:GetParent():SetAbsOrigin(self.target:GetAbsOrigin() + direction_from_caster_to_target * 128)		-- 128 = melee
	else
		-- if not we need to put ourselves on the correct axis and then advance
		self:GetParent():SetAbsOrigin(self.target:GetAbsOrigin() + direction_from_caster_to_target * (distance_from_wraith_to_target - 10))
	end
	self:GetParent():SetForwardVector(direction_from_caster_to_target * Vector(-1, -1, 0))
end

function modifier_wraith:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_ILLUSION_LABEL, MODIFIER_EVENT_ON_DEATH}
end

function modifier_wraith:OnAttackLanded(info)
	if info.attacker == self:GetParent() and not info.target:IsMagicImmune() then
		self.attacks_landed = self.attacks_landed + 1
		info.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_wraith_debuff", {duration = self:GetAbility():GetSpecialValueFor("debuff_duration")})
		if self.attacks_landed >= self:GetAbility():GetSpecialValueFor("wraith_max_hits") then
			self:Destroy()
		end
	end
end

function modifier_wraith:GetModifierIllusionLabel()
	return true
end

function modifier_wraith:GetModifierDamageOutgoing_Percentage_Illusion()
	return self:GetAbility():GetSpecialValueFor("wraith_damage_percent")
end

function modifier_wraith:OnDestroy()
	if not IsServer() then return end
	self:GetCaster():SwapAbilities("summon_wraith", "wraith_swap_positions", true, false)
	self:GetAbility():SetIntAttr("wraith_index", -1)
	local wraith = self:GetParent()
	wraith:ForceKill(false)
	-- Make sure it actually gets removed from the hero list and does not respawn
	Timers:CreateTimer(0.5, function()
		wraith:Destroy()
	end)
end

---

LinkLuaModifier("modifier_wraith_debuff", "heroes/wraith/summon_wraith", LUA_MODIFIER_MOTION_NONE)
modifier_wraith_debuff = class({})

function modifier_wraith_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_wraith_debuff:OnCreated()
	self.slow = self:GetAbility():GetSpecialValueFor("debuff_slow")
	if not IsServer() then return end
	self:SetStackCount(1)
end

function modifier_wraith_debuff:OnRefresh()
	if not IsServer() then return end
	self:IncrementStackCount()
end

function modifier_wraith_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * self.slow * -1
end

function modifier_wraith_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_wraith_debuff:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

---

wraith_swap_positions = class({})

function wraith_swap_positions:OnSpellStart()
	local caster = self:GetCaster()
	local main_ability = caster:FindAbilityByName("summon_wraith")
	if not main_ability then
		print("Couldn't find Summon Wraith...")
		return
	end
	local wraith_index = main_ability:GetIntAttr("wraith_index")
	if not wraith_index or wraith_index == -1 then
		print("Couldn't find a wraith to swap with...")
		return
	end
	local wraith = EntIndexToHScript(wraith_index)

	ParticleManager:CreateParticle("particles/generic_gameplay/illusion_killed.vpcf", PATTACH_POINT, caster)
	ParticleManager:CreateParticle("particles/generic_gameplay/illusion_killed.vpcf", PATTACH_POINT, wraith)

	ProjectileManager:ProjectileDodge(caster)
	ProjectileManager:ProjectileDodge(wraith)
	
	local casterorigin = caster:GetAbsOrigin()
	local casterfv = caster:GetForwardVector()
	FindClearSpaceForUnit(caster, wraith:GetAbsOrigin(), false)
	caster:SetForwardVector(wraith:GetForwardVector())
	wraith:SetAbsOrigin(casterorigin)
	wraith:SetForwardVector(casterfv)
end

function wraith_swap_positions:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_leap_strike") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function wraith_swap_positions:GetCustomCastError()
	return "#dota_hud_error_cant_use_while_leaping"
end