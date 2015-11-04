ItemGenerator = class({})

ItemGenerator.MIN_SPAWN_INTERVAL = 30
ItemGenerator.MAX_SPAWN_INTERVAL = 50
ItemGenerator.MIN_DELAY_AFTER_WARNING = 5
ItemGenerator.MAX_DELAY_AFTER_WARNING = 7

ItemGenerator.ITEMS = {
	"item_health_potion",
	"item_mana_potion",
	"item_bkb_fragment",
	"item_blink_shard",
	"item_enchanted_skull"
}
ItemGenerator.ITEM_PROBABILITIES = {
	item_health_potion = 1,
	item_mana_potion = 1,
	item_bkb_fragment = 0.5,
	item_blink_shard = 0.5,
	item_enchanted_skull = 0.5
}

ItemGenerator.status = "inactive"

function ItemGenerator:Start()
	-- Choose which item to spawn
	repeat
		ItemGenerator.next_item = ItemGenerator.ITEMS[RandomInt(1, #(ItemGenerator.ITEMS))]
		if RandomFloat(0, 1) > ItemGenerator.ITEM_PROBABILITIES[ItemGenerator.next_item] then
			ItemGenerator.next_item = nil
		end
	until ItemGenerator.next_item

	-- Choose where to put it
	repeat
		ItemGenerator.spawn_point = GetGroundPosition(RandomVector(RandomFloat(0, 800)), nil)
		if not GridNav:IsTraversable(ItemGenerator.spawn_point) or GridNav:IsBlocked(ItemGenerator.spawn_point) or GridNav:IsNearbyTree(ItemGenerator.spawn_point, 64, true) then
			ItemGenerator.spawn_point = nil
		end
	until ItemGenerator.spawn_point

	-- Choose how long to wait
	ItemGenerator.spawn_delay = RandomFloat(ItemGenerator.MIN_SPAWN_INTERVAL, ItemGenerator.MAX_SPAWN_INTERVAL)
	ItemGenerator.warn_delay = ItemGenerator.spawn_delay - RandomFloat(ItemGenerator.MIN_DELAY_AFTER_WARNING, ItemGenerator.MAX_DELAY_AFTER_WARNING)

	Timers:CreateTimer("item_generator", {
		endTime = ItemGenerator.spawn_delay,
		useGameTime = true,
		callback = ItemGenerator.SpawnItem
	})
	Timers:CreateTimer("item_generator_warning", {
		endTime = ItemGenerator.warn_delay,
		useGameTime = true,
		callback = ItemGenerator.IssueWarning
	})

	ItemGenerator.status = "started"
end

function ItemGenerator:IssueWarning()
	CustomGameEventManager:Send_ServerToAllClients("item_will_spawn", {item = ItemGenerator.next_item})
	local teams = {DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}
	for k,team in pairs(teams) do
		-- Doesn't matter what hero makes the minimap event, but it can't be nil.
		MinimapEvent(team, PlayerResource:GetPlayer(0):GetAssignedHero(), ItemGenerator.spawn_point.x, ItemGenerator.spawn_point.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2)
	end
	ItemGenerator.marker = ParticleManager:CreateParticle("particles/econ/events/fall_major_2015/teleport_start_fallmjr_2015_lvl2.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(ItemGenerator.marker, 0, ItemGenerator.spawn_point)
	ParticleManager:SetParticleControl(ItemGenerator.marker, 2, Vector(.07, .5, .07))
	AddFOWViewer(DOTA_TEAM_GOODGUYS, ItemGenerator.spawn_point, 100, ItemGenerator.warn_delay + 1, false)
	EmitGlobalSound("announcer_ann_custom_item_alerts_02")

	ItemGenerator.status = "warned"
end

function ItemGenerator:SpawnItem()
	CustomGameEventManager:Send_ServerToAllClients("item_has_spawned", {item = ItemGenerator.next_item})
	CreateItemOnPositionSync(ItemGenerator.spawn_point, CreateItem(ItemGenerator.next_item, nil, nil))
	local teams = {DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}
	for k,team in pairs(teams) do
		MinimapEvent(team, PlayerResource:GetPlayer(0):GetAssignedHero(), ItemGenerator.spawn_point.x, ItemGenerator.spawn_point.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2)
		EmitAnnouncerSoundForTeam("Portal.Hero_Appear", team)
	end
	ParticleManager:DestroyParticle(ItemGenerator.marker, false)
	EmitGlobalSound("announcer_ann_custom_item_alerts_03")

	ItemGenerator:Start()
end

function ItemGenerator:Stop()
	Timers:RemoveTimer("item_generator")
	Timers:RemoveTimer("item_generator_warning")
	if ItemGenerator.status == "warned" then
		ParticleManager:DestroyParticle(ItemGenerator.marker, true)
	end
	ItemGenerator.status = "inactive"
end