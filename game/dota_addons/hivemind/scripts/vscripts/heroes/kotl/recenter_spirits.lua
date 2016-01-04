recenter_spirits = class({})

function recenter_spirits:CastFilterResultLocation(loc)
	if not IsServer() then return end
	local modifier = self:GetCaster():FindModifierByName("modifier_summon_spirits")
	if not modifier or not modifier.center then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function recenter_spirits:GetCustomCastErrorLocation(loc)
	return "#dota_hud_error_no_spirits"
end

function recenter_spirits:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_recenter_spirits", {x = self:GetCursorPosition().x, y = self:GetCursorPosition().y})
end

---

LinkLuaModifier("modifier_recenter_spirits", "heroes/kotl/recenter_spirits", LUA_MODIFIER_MOTION_NONE)
modifier_recenter_spirits = class({})

function modifier_recenter_spirits:OnCreated(info)
	if not IsServer() then return end
	self.target = Vector(info.x, info.y, 0)
	self.movement_step = self:GetAbility():GetSpecialValueFor("center_movespeed") * 0.03
	self:StartIntervalThink(0.03)
end

function modifier_recenter_spirits:OnIntervalThink()
	local mod = self:GetCaster():FindModifierByName("modifier_summon_spirits")
	if mod and mod.center then
		local loc = mod.center:GetAbsOrigin()
		if DistanceBetweenVectors(loc, self.target) > self.movement_step then
			mod.center:SetAbsOrigin(GetGroundPosition(loc + DirectionFromAToB(loc, self.target) * self.movement_step, nil))
		else
			mod.center:SetAbsOrigin(GetGroundPosition(self.target, nil))
			self:Destroy()
		end
	else
		self:Destroy()
	end
end

function modifier_recenter_spirits:IsHidden()
	return true
end

function modifier_recenter_spirits:OnRefresh(info)
	self.target = Vector(info.x, info.y, 0)
end