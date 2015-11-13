"use strict";

var unitclasses = ["npc_dota_lycan_split_wolf", "npc_dota_bane_split_ghost", "npc_dota_phoenix_split_spirit", "npc_dota_enigma_split_eidolon", "npc_dota_wraith_split_skeleton", "npc_dota_tinker_split_clockwerk", "npc_dota_earth_spirit_split_tiny", "npc_dota_omniknight_split_angel", "npc_dota_shadow_demon_split_hellhound"]

for (var i = 0; i < $.GetContextPanel().Children().length; i++) {
	$.GetContextPanel().GetChild(i).SetAttributeInt("original_order", i)
}

function RebuildPanels(stuff) {
	var info = CustomNetTables.GetTableValue("split_units", Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()).toString())
	$.Msg("Regenerating split unit panel with the following data:")
	$.Msg(info)
	var parent = $.GetContextPanel()
	var children = parent.Children()
	var i = 0

	for (var k in parent.Children()) {
		children[k].SetAttributeInt("entindex", -1)
		children[k].SetHasClass("dead", false)
		children[k].style.visibility = "visible"
		for (var j = 0; j < unitclasses.length; j++) {
			children[k].SetHasClass(unitclasses[j], false)
		}
	}
 
	// Create panels
	for (var unit in info) {
		// Create unit panel
		var unitpanel = parent.GetChild(i)
		unitpanel.SetAttributeInt("entindex", parseInt(unit))
		var friendly_id = info[unit]["id"]
		unitpanel.SetAttributeInt("friendly_id", friendly_id)
		unitpanel.FindChildrenWithClassTraverse("unit-number")[0].text = friendly_id
		var unitname = info[unit]["unitname"]
		unitpanel.SetHasClass(unitname, true) // controls unit pic
		if (info[unit]["dead"]) {
			unitpanel.SetHasClass("dead", true)
		}
		// Create ability sub-panel
		var ability_container = unitpanel.FindChildrenWithClassTraverse("abilities")[0]
		var abilities = ability_container.Children()
		if (!info[unit]["dead"]) {
			for (var k in abilities) {
				abilities[k].SetAttributeInt("ability_entindex", -1)
				abilities[k].SetAttributeInt("unit_entindex", -1)
				abilities[k].GetChild(0).abilityname = ""
				abilities[k].style.visibility = "visible"
			}

			var ab_offset = 0
			for (var k = 0; k < Entities.GetAbilityCount(parseInt(unit)); k++) {
				var ab = Entities.GetAbility(parseInt(unit), k)
				var name = Abilities.GetAbilityName(ab)
				if (name != "" && name.substring(0,5) != "unify") {
					var abilitypanel = abilities[k - ab_offset]
					abilitypanel.SetAttributeInt("ability_entindex", ab)
					abilitypanel.SetAttributeInt("unit_entindex", parseInt(unit))
					abilitypanel.GetChild(0).abilityname = name
				} else {
					ab_offset = ab_offset + 1
				}
			}
		}
 
		for (var k in abilities) {
			if (abilities[k].GetAttributeInt("ability_entindex", -1) == -1) {
				abilities[k].style.visibility = "collapse"
			}
		}
		i = i + 1
	}
  
	children = parent.Children()
	for (var k in parent.Children()) {
		if (children[k].GetAttributeInt("entindex", -1) == -1) {
			children[k].style.visibility = "collapse"
		}
	}

	// Sort panels
	var panels = $.GetContextPanel().Children()
	var lastpanel
	for (var i in panels) {
		var id = panels[i].GetAttributeInt("friendly_id", -1)
		for (var j in panels) {
			if (i === j) {
				break
			} else {
				if (id < panels[j].GetAttributeInt("friendly_id", -1)) {
					$.GetContextPanel().MoveChildBefore(panels[i], panels[j])
					break
				}
			}
		}
	}

	var all_units = $.GetContextPanel().Children()
}

function UpdatePanels() {
	// Loop through panels
	var panels = $.GetContextPanel().Children()
	for (var i = 0; i < panels.length; i++) {
		// Update health
		var panel = panels[i]
		var ent = panel.GetAttributeInt("entindex", -1)
		if (ent != -1) {
			var pct = Entities.GetHealthPercent(ent)
			var fill_bar = panel.FindChildrenWithClassTraverse("health_bar_fill")[0]
			if (fill_bar != null) {
				fill_bar.style.width = pct.toString() + "%"
			}
		}

		// Update ability cooldowns
		var abilitypanels = panel.GetChild(1).Children()
		for (var j = 0; j < abilitypanels.length; j++) {
			var abilitypanel = abilitypanels[j]
			var abilityent = abilitypanel.GetAttributeInt("ability_entindex", -1)
			if (abilityent != -1 ) {
				abilitypanel.SetHasClass("cooldown", !Abilities.IsCooldownReady(abilityent))
			}
		}
	}

	$.Schedule(0.25, UpdatePanels)
}

function OnSplitHeroStart(info) {

}

function OnSplitHeroFinish(info) {
	var first = false
	for (var unit in info.units) {
		unit = parseInt(unit)
		// add to selection
		GameUI.SelectUnit(unit, !first)
		first = true
	}
}

function OnUnifyHeroStart(info) {

}

function OnUnifyHeroFinish(info) {

}

function OnEntityKilled(info) {
	var unit = info.entindex_killed;
	if (unit === Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
		// the local player died
	} else {
		// check if it's a split unit
		$.Each($.GetContextPanel().Children(), function(index, value) {
			if (index.GetAttributeInt("entindex", -1) === unit) {
				index.SetHasClass("dead", true);
				var abs = index.GetChild(1).Children()
				for (var i = 0; i < abs.length; i++) {
					abs[i].style.visibility = "collapse"
				}
			}
		});
	}
}

function SplitUnitClicked(unit) {
	var ent = GetPanelByOriginalOrder(unit).GetAttributeInt("entindex", -1)
	if (Entities.IsSelectable(ent)) {
		GameUI.SelectUnit(ent, false)
	}
}

function SplitUnitDoubleClicked(unit) {
	var ent = GetPanelByOriginalOrder(unit).GetAttributeInt("entindex", -1)
	if (Entities.IsSelectable(ent)) {
		GameEvents.SendCustomGameEventToServer("move_camera", {target: ent})
	}
}

function GetPanelByOriginalOrder(order) {
	for (var paneli = 0; paneli < $.GetContextPanel().Children().length; paneli++) {
		if ($.GetContextPanel().GetChild(paneli).GetAttributeInt("original_order", -1) == order) {
			return $.GetContextPanel().GetChild(paneli)
		}
	}
}

function OnMouseoverSplitAbility(unit, ability) {
	var abilitypanel = GetPanelByOriginalOrder(unit).GetChild(1).GetChild(ability)
	$.DispatchEvent("DOTAShowAbilityTooltip", abilitypanel, abilitypanel.GetChild(0).abilityname)
}

function OnMouseoutSplitAbility(unit, ability) {
	$.DispatchEvent("DOTAHideAbilityTooltip")
}

function OnSplitAbilityClicked(unit, ability) {
	var panel = GetPanelByOriginalOrder(unit).GetChild(1).GetChild(ability)
	var unit = panel.GetAttributeInt("unit_entindex", -1)
	var ability = panel.GetAttributeInt("ability_entindex", -1)
	if (Entities.IsSelectable(unit)) {
		GameUI.SelectUnit(unit, false)
		Abilities.ExecuteAbility(ability, unit, false)
	}
}

function OnSplitPanelToggled(info) {
	$.Msg("Hi")
	if (info.active) {
		$.GetContextPanel().style.visibility = "visible"
	} else {
		$.GetContextPanel().style.visibility = "collapse"
	}
}


(function()
{
	GameEvents.Subscribe("split_units_created", RebuildPanels);
	GameEvents.Subscribe("split_hero_started", OnSplitHeroStart);
	GameEvents.Subscribe("split_hero_finished", OnSplitHeroFinish);
	GameEvents.Subscribe("unify_hero_started", OnUnifyHeroStart);
	GameEvents.Subscribe("unify_hero_finished", OnUnifyHeroFinish);
	GameEvents.Subscribe("entity_killed", OnEntityKilled);
	RebuildPanels()
	UpdatePanels()
})();
 