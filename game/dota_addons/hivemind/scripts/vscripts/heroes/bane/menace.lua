set_menace_location = class({})

function set_menace_location:OnSpellStart()
	local menace = self:GetCaster():FindAbilityByName("menace")
	local location_thinker = CreateModifierThinker(self:GetCaster(), self, "modifier_menace_location", {duration = menace:GetSpecialValueFor("set_duration")}, self:GetCursorPosition(), self:GetCaster():GetTeam(), false)
	self:GetCaster():SwapAbilities("set_menace_location", "menace", false, true)
	menace:Attribute_SetIntValue("location_thinker_entindex", location_thinker:GetEntityIndex())
end

---

LinkLuaModifier("modifier_menace_location", "heroes/bane/menace", LUA_MODIFIER_MOTION_NONE)
modifier_menace_location = class({})

function modifier_menace_location:OnDestroy()
	if not IsServer() then return end
	self:GetCaster():SwapAbilities("set_menace_location", "menace", true, false)
end

function modifier_menace_location:GetEffectName()
	return "particles/units/heroes/hero_bane/bane_enfeeble_grand.vpcf"
end

function modifier_menace_location:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---

menace = class({})

function menace:GetAOERadius()
	return 400
end

function menace:OnSpellStart()
	local location_thinker = self:Attribute_GetIntValue("location_thinker_entindex", -1)
	if location_thinker == -1 then
		print("Uh oh... couldn't find a location thinker")
		return
	else
		location_thinker = EntIndexToHScript(location_thinker)
	end

	local center = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("ring_radius")
	-- Find the point on the above circle which is the closest to the thinker's origin. That's where the real Mara will appear.
	-- To do that, we take the direction from the center to the thinker and multiply by the radius.
	local real_loc = center + (((location_thinker:GetAbsOrigin() - center) * Vector(1,1,0)):Normalized() * radius)
	-- Don't need this anymore:
	location_thinker:ForceKill(false)
	
	-- Now we need to calculate where the 7 illusions go.
	-- I don't remember what sines and cosines are...
	-- http://stackoverflow.com/questions/28075311/drawing-a-circle-with-an-evenly-distributed-set-amount-of-points
	local x,y
	local n = 8
	local r = radius
	local x0 = center.x
	local y0 = center.y
	local da = 2.0 * math.pi/n

	local a = 360

	for i = 0, n - 1 do
	    x = x0 + r * math.cos(a)
	    y = y0 + r * math.sin(a)
	    if i == 0 then
	   		DebugDrawCircle(Vector(x,y,0), Vector(0,255,0), 1, 100, true, 1)
	   	else
	   		DebugDrawCircle(Vector(x,y,0), Vector(255,0,0), 1, 100, true, 1)
	   	end
	    a = a + da
	end
end