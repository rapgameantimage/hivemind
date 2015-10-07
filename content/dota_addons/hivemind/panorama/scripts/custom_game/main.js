"use strict";

var POST_ROUND_DELAY = 5
var END_GAME_DELAY = 2

var next_countdown
var round = 0
var nextround

function CheckGamestate(table, key, value) {
	value = value["1"]
	if (key == "status") {
		if (value == "between_rounds") {
			RoundCountdown()
		} else if (value == "gameplay") {
			NewRound(CustomNetTables.GetTableValue("gamestate", "round")["1"])
		} else if (value == "finished") {
			$.Schedule(END_GAME_DELAY, EndGame)
		}
	} else if (key == "round") {
		round = value
	}
}

function OnRoundStarted(event) { 
	var num = CustomNetTables.GetTableValue("gamestate", "round")["1"]
	$("#pick").style.visibility = "collapse"		// just in case
	SetAlert(5, $.Localize("#round") + " " + num)
}

function OnRoundCompleted(event) {
	$.Msg("OnRoundCompleted")
	$("#pick").style.visibility = "collapse"		// just in case
	round = CustomNetTables.GetTableValue("gamestate", "round")["1"]
	nextround = parseInt(round + 1)
	next_countdown = POST_ROUND_DELAY
	IncrementCountdown()
}

function IncrementCountdown() {
	SetAlert(1, $.Localize("#round") + " " + nextround + " " + $.Localize("#in") + " " + next_countdown + $.Localize("ellipses"))
	next_countdown = next_countdown - 1
	if (next_countdown > 0) {
		$.Schedule(1, IncrementCountdown)
	}
}

function OnMatchCompleted(event) {
	var team = event.winning_team
	var details = Game.GetTeamDetails(team)
	var winner = ""
	if ( details.team_num_players == 1) {
		winner = Players.GetPlayerName(Game.GetPlayerIDsOnTeam(team)[0])
	} else {
		winner = details.team_name
	}
	$.Schedule(END_GAME_DELAY, function() {
		$("#winner").text = winner + " " + $.Localize("#wins")
		$("#winner").style.visibility = "visible"
		$("#rematch").text = $.Localize("#rematch_question")
		$("#rematch").style.visibility = "visible"
		$("#rematch-buttons").style.visibility = "visible"
		$("#gameover").style.visibility = "visible"
	})
}

function OnRematchAccepted() {
	$.Msg("It's a rematch!")
	$("#gameover").style.visibility = "collapse"
	
	CreatePickBoard()
	$("#pick").style.visibility = "visible"
}

function SetAlert(time, message) {
	$("#alert-text").text = message
	$("#alert-text").SetHasClass("visible", true)
	if (isNaN(time)) {
		$.Msg("SetAlert called with non-numeric time (" + time + ")")
		return
	}
	$.Schedule(time, function() {
		if ($("#alert-text").text === message) {
			$("#alert-text").SetHasClass("visible", false)
		}
	})
}

function RematchYes() {
	$("#rematch").text = $.Localize("#rematch_waiting")
	$("#rematch-buttons").style.visibility = "collapse"
	GameEvents.SendCustomGameEventToServer("rematch_yes", {
		player: Players.GetLocalPlayer()
	})
}

function RematchNo() {
	$("#gameover").style.visibility = "collapse"
	GameEvents.SendCustomGameEventToServer("rematch_no", {
		player: Players.GetLocalPlayer()
	})
}

function OnRematchNo() {
	$("#rematch").text = $.Localize("#rematch_declined")
	$("#rematch-buttons").style.visibility = "collapse"
	$.Schedule(3, function() {
		$("#gameover").style.visibility = "collapse"
	})
}

function CreatePickBoard() {
	var pickable_heroes = ["npc_dota_hero_lycan", "npc_dota_hero_bane", "npc_dota_hero_phoenix", "npc_dota_hero_enigma", "npc_dota_hero_skeleton_king"]
	var heroes_per_row = 2
	var parent = $("#pick")

	var number_of_rows = Math.ceil(pickable_heroes.length / heroes_per_row)

	parent.RemoveAndDeleteChildren()
	var header = $.CreatePanel("Panel", parent, "pick-header")
	header.BLoadLayout("file://{resources}/layout/custom_game/pick_header.xml", false, false)

	for (var i = 0; i < number_of_rows; i++) {
		var row = $.CreatePanel("Panel", parent, "")
		row.SetHasClass("pick-row", true)
		for (var j = i * heroes_per_row; j < (i + 1) * heroes_per_row; j++) {
			if (j < pickable_heroes.length) {
				var hero = $.CreatePanel("Panel", row, "")
				hero.BLoadLayout("file://{resources}/layout/custom_game/pick_hero.xml", false, false)
				hero.GetChild(0).heroname = pickable_heroes[j]
			}
		}
	}
} 

function OnNewHeroPicked(event) {
	// This is just cosmetic. The event is sent to the server in pick_hero.js
	var parent = $("#pick")
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
} 

function OnMatchStarted() {
	$("#pick").style.visibility = "collapse"
}

function OnEntityKilled(event) {
	// Deselects killed units from multi-select groups, so the player's commands don't keep getting delivered to a dead unit
	// First, see if the dead unit is selected
	var entity_killed = event.entindex_killed
	var selection = Players.GetSelectedEntities(0)
	var index = selection.indexOf(entity_killed)
	if (index != -1) {
		// If so, remove it from the array
		selection.splice(index, 1)
		// Since there's no way to de-select an individual unit, we need to rebuild the whole selection
		var first = true
		for (var i = 0; i < selection.length; i++) {
			GameUI.SelectUnit(selection[i], !first)
			first = false
		}
	}
}

function OnArenaShrink(event) {
	SetAlert(3, $.Localize("#arena_shrink"))
}

(function()
{
	CreatePickBoard()		// This is actually called every time there is a rematch so isn't technically necessary to be here

	//CustomNetTables.SubscribeNetTableListener("gamestate", CheckGamestate)
	GameEvents.Subscribe("rematch_no", OnRematchNo)
	GameEvents.Subscribe("rematch_accepted", OnRematchAccepted)
	GameEvents.Subscribe("new_hero_picked", OnNewHeroPicked)
	GameEvents.Subscribe("round_started", OnRoundStarted)
	GameEvents.Subscribe("round_completed", OnRoundCompleted)
	GameEvents.Subscribe("match_started", OnMatchStarted)
	GameEvents.Subscribe("match_completed", OnMatchCompleted)
	GameEvents.Subscribe("entity_killed", OnEntityKilled)
	GameEvents.Subscribe("arena_shrink", OnArenaShrink)
})();