var hero_picked = ""
var pickable_heroes = ["npc_dota_hero_lycan", "npc_dota_hero_bane", "npc_dota_hero_phoenix", "npc_dota_hero_enigma", "npc_dota_hero_skeleton_king", "npc_dota_hero_tinker", "npc_dota_hero_earth_spirit", "npc_dota_hero_omniknight"]
var hero_abilities = {
	"npc_dota_hero_lycan": ["split_lycan", "lycan_hamstring", "lycan_skull_crush", "lycan_berserk", "lycan_echoing_howl"],
	"npc_dota_hero_bane": ["split_bane", "bane_flicker", "bane_nightmare_orb", "ectoplasm", "phantom"],
	"npc_dota_hero_phoenix": ["split_phoenix", "sticky_flame", "molten_body", "fiery_birth", "swoop"],
	"npc_dota_hero_enigma": ["split_enigma", "dimensional_bind", "repulsion", "crippling_gravity", "singularity"],
	"npc_dota_hero_skeleton_king": ["split_wraith", "wraithpyre", "ghostly_fireball", "summon_wraith", "leap_strike"],
	"npc_dota_hero_tinker": ["split_tinker", "missile_swarm", "orbital_laser", "hover_boots", "pulse_cannon"],
	"npc_dota_hero_earth_spirit": ["split_earth_spirit", "rock_wave", "quake", "magnetizing_strike", "earthen_passage"],
	"npc_dota_hero_omniknight": ["split_omniknight", "ablution", "judgment", "wrath", "retribution"]
}
var split_abilities = {
	"npc_dota_lycan_split_wolf": ["unify_lycan", "lycan_pounce", "lycan_lacerate"],
	"npc_dota_bane_split_ghost": ["unify_bane", "bane_chilling_scream", "ephemeral"],
	"npc_dota_phoenix_split_spirit": ["unify_phoenix", "firewall", "dissolution"],
	"npc_dota_enigma_split_eidolon": ["unify_enigma", "puck_phase_shift", "distant_malice"],
	"npc_dota_wraith_split_skeleton": ["unify_wraith", "throw_bone", "arcane_etchings"],
	"npc_dota_tinker_split_clockwerk": ["unify_tinker", "discharge", "hookshot"],
	"npc_dota_earth_spirit_split_tiny": ["unify_earth_spirit", "throw_rockling", "heavyweight"],
	"npc_dota_omniknight_split_angel": ["unify_omniknight", "smite", "holy_infusion", "avenging_angel"]
}
var unit_info = {}

function CreatePickBoard() {
	hero_picked = ""

	// Reset text of header and tips area
	$("#pick-header-label").text = $.Localize("#pick_header_text")
	$("#pick-tips-label").text = $.Localize("#pick_tips_nohero")

	// Hide showcases
	$("#hero-form-showcase").style.visibility = "collapse"
	$("#split-form-showcase").style.visibility = "collapse"

	// Generate possible heroes and a random button
	var heroes_per_row = 5
	var parent = $("#pick-buttons-area")

	var number_of_rows = Math.ceil(pickable_heroes.length + 1 / heroes_per_row)
	var created_random_button = false

	parent.RemoveAndDeleteChildren()

	for (var i = 0; i < number_of_rows; i++) {
		var row = $.CreatePanel("Panel", parent, "")
		row.SetHasClass("pick-row", true)
		for (var j = i * heroes_per_row; j < (i + 1) * heroes_per_row; j++) {
			if (j < pickable_heroes.length) {
				var hero = $.CreatePanel("Panel", row, "")
				hero.BLoadLayout("file://{resources}/layout/custom_game/pick_hero.xml", false, false)
				hero.GetChild(0).heroname = pickable_heroes[j]
				hero.SetHasClass("enabled", true)
			} else if (!created_random_button) {
				var random = $.CreatePanel("Panel", row, "")
				random.BLoadLayout("file://{resources}/layout/custom_game/random_hero.xml", false, false)
				random.GetChild(0).heroname = "random"
				random.SetHasClass("enabled", true)
				created_random_button = true
			}
		}
	}

	// Disable pick button
	$("#pick-confirm-button-label").text = $.Localize("#pick")
	$("#pick-confirm-button").SetHasClass("enabled", false)

	// Save unit info for displaying later when the player clicks a hero
	for (var i = 0; i < pickable_heroes.length; i++) {
		unit_info[pickable_heroes[i]] = CustomNetTables.GetTableValue("unit_info", pickable_heroes[i])
	}
}
 
function OnPickscreenHeroClicked(event) {
	hero_picked = event.hero

	// Gray out the other heroes
	var parent = $("#pick-buttons-area")
	$.Each(parent.FindChildrenWithClassTraverse("pick-row"), function(index, value) {
		$.Each(index.Children(), function(index, value) {
			if (index.GetChild(0).heroname == event.hero) {
				index.SetHasClass("picked", true)
				index.SetHasClass("unpicked", false)
			} else {
				index.SetHasClass("picked", false)
				index.SetHasClass("unpicked", true)
			}
		})
	})

	// Enable the pick button
	$("#pick-confirm-button").SetHasClass("enabled", true)

	// Treat random specially
	if (hero_picked === "random") {
		$("#hero-form-showcase").style.visibility = "collapse"
		$("#split-form-showcase").style.visibility = "collapse"
		$("#pick-tips-label").text = $.Localize("#pick_tips_random")
		$("#pick-confirm-button-label").text = $.Localize("#random")
		// We don't want to do any of the other stuff because we don't have a showcase or anything.
		return
	}

	var heroname = "npc_dota_hero_" + hero_picked

	$("#pick-confirm-button-label").text = $.Localize("#pick") + " " + $.Localize(heroname)

	// Update the hero showcase
	$("#hero-form-label").text = $.Localize("#hero_form") + ": " + $.Localize("#" + heroname)
	$("#hero-form-image").heroname = heroname

	$("#hero-form-ability-showcase").RemoveAndDeleteChildren()
	var abilities = hero_abilities[heroname]
	if (abilities) {
		for (var i = 0; i < abilities.length; i++) {
			var ability = $.CreatePanel("Panel", $("#hero-form-ability-showcase"), "")
			ability.BLoadLayout("file://{resources}/layout/custom_game/pick_ability.xml", false, false)
			ability.GetChild(0).abilityname = abilities[i]
		}
	}

	var splitname = unit_info[heroname].split_unit_name
	
	// Update the split form showcase
	$("#split-form-label").text = $.Localize("#split_form") + ": " + $.Localize("#" + splitname) + " " + $.Localize("#multiplication") + unit_info[heroname].split_unit_count
	
	// Need to get rid of whatever other classes are on the image before we can set it
	$.Each(unit_info, function(index, value) {
		$("#split-form-image").SetHasClass(index.split_unit_name, false)
	})
	$("#split-form-image").SetHasClass(splitname, true)

	$("#split-form-ability-showcase").RemoveAndDeleteChildren()
	var abilities = split_abilities[splitname]
	if (abilities) {
		for (var i = 0; i < abilities.length; i++) {
			var ability = $.CreatePanel("Panel", $("#split-form-ability-showcase"), "")
			ability.BLoadLayout("file://{resources}/layout/custom_game/pick_ability.xml", false, false)
			ability.GetChild(0).abilityname = abilities[i]
		}
	}

	// Display showcases in case they were hidden
	$("#hero-form-showcase").style.visibility = "visible"
	$("#split-form-showcase").style.visibility = "visible"

	// Update tips
	$("#pick-tips-label").text = $.Localize("#pick_tips_" + heroname)
} 

function OnPickButtonPressed() {
	if ($("#pick-confirm-button").BHasClass("enabled")) {

		// Disable buttons
		var parent = $("#pick-buttons-area")
		$.Each(parent.FindChildrenWithClassTraverse("pick-row"), function(index, value) {
			$.Each(index.Children(), function(index, value) {
				index.SetHasClass("enabled", false)
			})
		})

		if (hero_picked === "random") {
			// Choose a random hero for the player
			var num = Math.floor(Math.random() * pickable_heroes.length)
			hero_picked = pickable_heroes[num]
			// We need to strip away npc_dota_hero_ because for some reason DOTAHeroImage does it so we have to be uniform
			hero_picked = hero_picked.substring(14)
			// Act as if the player clicked this hero, so they can see who they randomed if they're waiting
			OnPickscreenHeroClicked({hero: hero_picked})
		}

		$("#pick-confirm-button").SetHasClass("enabled", false)

		GameEvents.SendCustomGameEventToServer("new_hero_picked", {hero: hero_picked})

		Game.EmitSound("HeroPicker.Selected")
	}
}

function OnOpponentDidntPickYet() {
	$("#pick-header-label").text = $.Localize("#pick_header_waiting_for_opponent")
}

(function() {

	CreatePickBoard()
	GameEvents.Subscribe("pickscreen_hero_clicked", OnPickscreenHeroClicked)
	GameEvents.Subscribe("opponent_didnt_pick_yet", OnOpponentDidntPickYet)
	GameEvents.Subscribe("rematch_accepted", CreatePickBoard)

})()