"use strict";

var PATTACH_OVERHEAD_FOLLOW = 7;

var number_particles = [];

function UpdatePanels(stuff) {
	DestroyPanels()
	var info = CustomNetTables.GetTableValue("split_units", Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()).toString())
	$.Msg("Regenerating split unit panel with the following data:")
	$.Msg(info)
	// Create panels
	for (var unit in info) {
		// Create unit panel
		var unitpanel = $.CreatePanel("Panel", $.GetContextPanel(), "unit")
		unitpanel.SetAttributeInt("entindex", parseInt(unit))
		var friendly_id = info[unit]["id"]
		unitpanel.SetAttributeInt("friendly_id", friendly_id)
		unitpanel.BLoadLayout("file://{resources}/layout/custom_game/split_unit.xml", false, false) 
		unitpanel.FindChildrenWithClassTraverse("unit-number")[0].text = friendly_id
		var unitname = info[unit]["unitname"]
		unitpanel.Children()[0].SetHasClass(unitname, true) // controls unit pic
		if (info[unit]["dead"]) {
			unitpanel.SetHasClass("dead", true)
		} else {
			// Create ability sub-panel
			for (var i = 0; i < Entities.GetAbilityCount(parseInt(unit)); i++) {
				var ab = Entities.GetAbility(parseInt(unit), i)
				var name = Abilities.GetAbilityName(ab)
				if (name != "" && name.substring(0,5) != "unify") {
					var abilitypanel = $.CreatePanel("Panel", unitpanel.FindChildrenWithClassTraverse("abilities")[0], "ability")
					abilitypanel.SetAttributeInt("ability_entindex", ab)
					abilitypanel.SetAttributeInt("unit_entindex", parseInt(unit))
					abilitypanel.BLoadLayout("file://{resources}/layout/custom_game/split_unit_ability.xml", false, false)
					abilitypanel.Children()[0].Children()[0].abilityname = name
				}
			}
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

function OnSplitHeroStart(info) {

}

function OnSplitHeroFinish(info) {
	var first = false
	for (var unit in info.units) {
		unit = parseInt(unit)
		// add to selection
		GameUI.SelectUnit(unit, !first)
		first = true

		// create overhead numbers
		// maybe re-implement some other time
		/*
		var fx = Particles.CreateParticle("particles/split_count.vpcf", PATTACH_OVERHEAD_FOLLOW, unit, Players.GetLocalPlayer())
		number_particles.push(fx)
		Particles.SetParticleControl(fx, 1, [0,0,0])
		*/
	}
}

function OnUnifyHeroStart(info) {

}

function OnUnifyHeroFinish(info) {
	while (number_particles[0] != null) {
		Particles.DestroyParticleEffect(number_particles.pop(), true);
	}
}

function OnEntityKilled(info) {
	var unit = info.entindex_killed;
	if (unit === Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
		// the local player died
		DestroyPanels()
	} else {
		// check if it's a split unit
		$.Each($.GetContextPanel().Children(), function(index, value) {
			if (index.GetAttributeInt("entindex", -1) === unit) {
				index.SetHasClass("dead", true);
				index.GetChild(0).GetChild(1).RemoveAndDeleteChildren()
			}
		});
	}
}

function DestroyPanels() {
	if ($.GetContextPanel().GetChildCount() > 0) {
		$.Each($.GetContextPanel().Children(), function(panel, x) {
			panel.RemoveAndDeleteChildren()
		})
	}
}

(function()
{
	GameEvents.Subscribe("split_units_created", UpdatePanels);
	GameEvents.Subscribe("split_hero_started", OnSplitHeroStart);
	GameEvents.Subscribe("split_hero_finished", OnSplitHeroFinish);
	GameEvents.Subscribe("unify_hero_started", OnUnifyHeroStart);
	GameEvents.Subscribe("unify_hero_finished", OnUnifyHeroFinish);
	GameEvents.Subscribe("entity_killed", OnEntityKilled);
	UpdatePanels();
})();
