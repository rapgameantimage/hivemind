"use strict"

function OnClickHero() {
	var panel = $.GetContextPanel()
	var heroname = panel.GetChild(0).heroname
	GameEvents.SendEventClientSide("new_hero_picked", {hero: heroname})
	GameEvents.SendCustomGameEventToServer("new_hero_picked", {hero: heroname})
}