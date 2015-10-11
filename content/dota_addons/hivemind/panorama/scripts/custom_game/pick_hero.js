"use strict"

function OnClickHero() {
	var panel = $.GetContextPanel()
	if (panel.BHasClass("enabled")) {
		var heroname = panel.GetChild(0).heroname
		GameEvents.SendEventClientSide("pickscreen_hero_clicked", {hero: heroname})
	}
}

function OnClickRandomHero() {
	var panel = $.GetContextPanel()
	if (panel.BHasClass("enabled")) {
		GameEvents.SendEventClientSide("pickscreen_hero_clicked", {hero: "random"})
	}
}