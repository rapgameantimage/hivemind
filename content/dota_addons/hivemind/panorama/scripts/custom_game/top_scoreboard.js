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

function UpdateTopBar() {
	var player1 = Game.GetPlayerIDsOnTeam(DOTA_TEAM_GOODGUYS)[0]
	var player2 = Game.GetPlayerIDsOnTeam(DOTA_TEAM_BADGUYS)[0]
	var scores = CustomNetTables.GetTableValue("gamestate", "score")

	// 0 is a valid player number, so can't just do if (player1)
	if (player1 != null) {
		var name1 = Players.GetPlayerName(player1)
		if (name1) {
			$("#left-name").GetChild(0).text = name1
		} else {
			$("#left-name").GetChild(0).text = ""
		}

		var hero1 = Players.GetPlayerHeroEntityIndex(player1)
		if (hero1) {
			$("#left-hero").SetAttributeInt("hero", hero1)
			$("#left-hero").GetChild(0).heroname = Entities.GetClassname(hero1)
		} else {
			$("#left-hero").SetAttributeInt("hero", -1)
			$("#left-hero").GetChild(0).heroname = ""
		}

		var score1 = scores[DOTA_TEAM_GOODGUYS_str]
		if (score1) {
			$("#left-score").text = score1
		} else {
			$("#left-score").text = "0"
		}
	}

	if (player2 != null) {
		var name2 = Players.GetPlayerName(player2)
		if (name2) {
			$("#right-name").GetChild(0).text = name2
		} else {
			$("#right-name").GetChild(0).text = ""
		}

		var hero2 = Players.GetPlayerHeroEntityIndex(player2)
		if (hero2) {
			$("#right-hero").SetAttributeInt("hero", hero2)
			$("#right-hero").GetChild(0).heroname = Entities.GetClassname(hero2)
		} else {
			$("#right-hero").SetAttributeInt("hero", -1)
			$("#right-hero").GetChild(0).heroname = ""
		}

		var score2 = scores[DOTA_TEAM_BADGUYS_str]
		if (score2) {
			$("#right-score").text = score2
		} else {
			$("#right-score").text = "0"
		} 
	}
}
 
(function()
{
	UpdateTopBar()
	
	//CustomNetTables.SubscribeNetTableListener("gamestate", CheckState)
	GameEvents.Subscribe("dota_player_pick_hero", UpdateTopBar)
	GameEvents.Subscribe("match_started", UpdateTopBar)
	GameEvents.Subscribe("match_completed", UpdateTopBar)
	GameEvents.Subscribe("round_completed", UpdateTopBar)
	GameEvents.Subscribe("round_started", UpdateTopBar)
})();