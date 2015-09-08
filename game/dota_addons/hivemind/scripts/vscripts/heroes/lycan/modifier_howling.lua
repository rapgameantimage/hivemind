modifier_howling = class({})

function modifier_howling:OnCreated()
	if IsServer() then
		self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("echo_interval"))
		self:OnIntervalThink(true)
	end
end

function modifier_howling:OnIntervalThink(first)
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local slow_duration = ability:GetSpecialValueFor("slow_duration")
	local units = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, 0, 0, false)
	for x,unit in pairs(units) do
		unit:AddNewModifier(parent, ability, "modifier_howling_slow", {duration = slow_duration})
	end
	if not first then
		ParticleManager:CreateParticle("particles/heroes/lycan/howl_echo.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		StartSoundEvent("Hero_Lycan.Howl.Team", parent)
	end
end