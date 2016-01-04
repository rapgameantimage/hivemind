ethereal_forest = class({})

function ethereal_forest:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ethereal_forest", {duration = self:GetSpecialValueFor("buff_duration")})
end

---

LinkLuaModifier("modifier_ethereal_forest", "heroes/treant/ethereal_forest", LUA_MODIFIER_MOTION_NONE)
modifier_ethereal_forest = class({})

function modifier_ethereal_forest:OnCreated()
	if not IsServer() then return end
	self.recent_positions = {}
	self:StartIntervalThink(0.1)
end

function modifier_ethereal_forest:OnIntervalThink()
	for k,pos in pairs(self.recent_positions) do
		if not Entities:FindByClassnameWithin(nil, "dota_temp_tree", pos, 32) and not Entities:FindByClassnameWithin(nil, "env_dota_tree", pos, 32) and DistanceBetweenVectors(self:GetParent():GetAbsOrigin(), pos) > 70 then
			CreateTempTree(pos, self:GetAbility():GetSpecialValueFor("tree_duration"))
			ResolveNPCPositions(pos, 70)
			for k2,pos2 in pairs(self.recent_positions) do
				if DistanceBetweenVectors(pos, pos2) < 64 or GameRules:GetGameTime() - k2 > 2 then
					self.recent_positions[k2] = nil
				end
			end
		end
	end
	self.recent_positions[GameRules:GetGameTime()] = self:GetParent():GetAbsOrigin()
end