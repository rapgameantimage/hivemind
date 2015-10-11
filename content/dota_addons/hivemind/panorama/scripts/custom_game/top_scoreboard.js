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
	var scoretext = ""

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
			var heroclass = Entities.GetClassname(hero1)
			if (heroclass != "npc_dota_hero_wisp") {
				$("#left-hero").GetChild(0).heroname = heroclass
			}
		} else {
			$("#left-hero").SetAttributeInt("hero", -1)
			$("#left-hero").GetChild(0).heroname = ""
		}

		var score1 = scores[DOTA_TEAM_GOODGUYS_str]
		if (score1) {
			scoretext = score1.toString()
		} else {
			scoretext = "0"
		}
	}

	scoretext = scoretext + "  -  "

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
			var heroclass = Entities.GetClassname(hero2)
			if (heroclass != "npc_dota_hero_wisp") {
				$("#right-hero").GetChild(0).heroname = heroclass
			}
		} else {
			$("#right-hero").SetAttributeInt("hero", -1)
			$("#right-hero").GetChild(0).heroname = ""
		}

		var score2 = scores[DOTA_TEAM_BADGUYS_str]
		if (score2) {
			scoretext = scoretext + score2.toString()
		} else {
			scoretext = scoretext + "0"
		} 
	}

	$("#scoretext").text = scoretext
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