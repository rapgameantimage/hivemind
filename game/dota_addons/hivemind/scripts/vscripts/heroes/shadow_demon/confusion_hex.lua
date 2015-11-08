confusion_hex = class({})

function confusion_hex:OnSpellStart()
	local caster = self:GetCaster()
	local direction = DirectionFromAToB(caster:GetAbsOrigin(), self:GetCursorPosition())
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/neutral_fx/satyr_hellcaller.vpcf",
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = direction * 1000,
		fDistance = 1000,
		fStartRadius = 50,
		fEndRadius = 150,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
	})
end

function confusion_hex:OnProjectileHit(target, loc)
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_confusion", {duration = 5})
		return true
	end
end

---

LinkLuaModifier("modifier_confusion", "heroes/shadow_demon/confusion_hex", LUA_MODIFIER_MOTION_NONE)
modifier_confusion = class({})

function modifier_confusion:OnCreated()
	if not IsServer() then return end
	--self:StartIntervalThink(0.25)

	self.filter = FilterManager:AddFilter("order", function(context, order)
		PrintTable(order)
		order.position_x = order.position_x + RandomFloat(-300, 300)
		order.position_y = order.position_y + RandomFloat(-300, 300)
		return true
	end, self)
end

function modifier_confusion:OnIntervalThink()
	--self:GetParent():SetForwardVector(self:GetParent():GetForwardVector() + RandomVector(0.5))
end

function modifier_confusion:OnDestroy()
	if not IsServer() then return end
	FilterManager:RemoveFilter(self.filter)
end