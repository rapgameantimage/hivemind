"use strict"

var DOTA_TEAM_GOODGUYS = 2
var DOTA_TEAM_GOODGUYS_str = "2"
var DOTA_TEAM_BADGUYS = 3
var DOTA_TEAM_BADGUYS_str = "3"

function CheckState(table, key, value) {
	if (key === "score") {
		$.Msg(value)
		$("#left-score").text = value[DOTA_TEAM_GOODGUYS_str]
		$("#right-score").text = value[DOTA_TEAM_BADGUYS_str]
	}
}

function OnIconClicked(panel) {
	var hero = $("#" + panel + "-hero").GetAttributeInt("hero", -1)
	if (hero != -1) {
		if (Entities.IsControllableByPlayer(hero, Players.GetLocalPlayer()) && Entities.IsSelectable(hero)) {
			GameUI.SelectUnit(hero, false)
		}
	}
}

function OnIconDoubleClicked(panel) {
	var hero = $("#" + panel + "-hero").GetAttributeInt("hero", -1)
	if (hero != -1) {
		if (Entities.IsControllableByPlayer(hero, Players.GetLocalPlayer()) && Entities.IsSelectable(hero)) {
			GameEvents.SendCustomGameEventToServer("move_camera", {target: hero})
		}
	}
}

function BuildTopBar() {
	$.Msg("Building top scoreboard")
	var left_team = Game.GetPlayerIDsOnTeam(DOTA_TEAM_GOODGUYS)
	var right_team = Game.GetPlayerIDsOnTeam(DOTA_TEAM_BADGUYS)

	$("#left-wrap").RemoveAndDeleteChildren()
	for (var i = 0; i < left_team.length; i++) {
		var player = left_team[i]
		var panel = $.CreatePanel("Panel", $("#left-wrap"), "")
		panel.SetAttributeInt("player", player)
		panel.BLoadLayout("file://{resources}/layout/custom_game/top_scoreboard_player_left.xml", false, false)
	}
   
	$("#right-wrap").RemoveAndDeleteChildren()
	for (var i = 0; i < right_team.length; i++) {
		var player = right_team[i]
		var panel = $.CreatePanel("Panel", $("#right-wrap"), "")
		panel.SetAttributeInt("player", player)
		panel.BLoadLayout("file://{resources}/layout/custom_game/top_scoreboard_player_right.xml", false, false)
	}
	UpdateTopBar()
} 
 
function UpdateTopBar() {
	var left_team = $("#left-wrap").Children()
	var right_team = $("#right-wrap").Children()

	for (var i = 0; i < left_team.length; i++) {
		var panel = left_team[i]
		var player = panel.GetAttributeInt("player", -1)
		var hero = Players.GetPlayerHeroEntityIndex(player)
		var heroclass = Entities.GetClassname(hero)
		if (heroclass != "npc_dota_hero_wisp") {
			panel.GetChild(0).heroname = heroclass
			panel.GetChild(0).SetAttributeInt("hero", hero)
		}

		var name = Players.GetPlayerName(player)
		if (name) {
			panel.GetChild(1).text = name
		} else {
			panel.GetChild(1).text = ""
		}
	}
   
	for (var i = 0; i < right_team.length; i++) {
		var panel = right_team[i]
		var player = panel.GetAttributeInt("player", -1)
		var hero = Players.GetPlayerHeroEntityIndex(player)
		var heroclass = Entities.GetClassname(hero)
		if (heroclass != "npc_dota_hero_wisp") {
			panel.GetChild(1).heroname = heroclass
			panel.GetChild(1).SetAttributeInt("hero", hero)
		}

		var name = Players.GetPlayerName(player)
		if (name) {
			panel.GetChild(0).text = name
		} else {
			panel.GetChild(0).text = ""
		}
	}

	var scores = CustomNetTables.GetTableValue("gamestate", "score")
	var scoretext = ""
	if (scores) {
		if (scores[DOTA_TEAM_GOODGUYS]) {
			scoretext = scores[DOTA_TEAM_GOODGUYS]
		} else {
			scoretext = "0"
		}
		scoretext = scoretext + "  -  "
		if (scores[DOTA_TEAM_BADGUYS]) {
			scoretext = scoretext + scores[DOTA_TEAM_BADGUYS]
		} else {
			scoretext = scoretext + "0"
		}
	} else {
		scoretext = "0  -  0"
	}
	$("#scoretext").text = scoretext
} 
 
(function()
{
	BuildTopBar()
	
	GameEvents.Subscribe("match_started", UpdateTopBar)
	GameEvents.Subscribe("match_completed", UpdateTopBar)
	GameEvents.Subscribe("round_completed", UpdateTopBar)
	GameEvents.Subscribe("round_started", UpdateTopBar)

	GameEvents.Subscribe("player_team", BuildTopBar)
	GameEvents.Subscribe("player_reconnected", BuildTopBar)
})(); 