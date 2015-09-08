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
		} else if (value == "rematch") {
			Rematch()
		}
	} else if (key == "round") {
		round = value
	}
}

function NewRound(num) { 
	SetAlert(5, $.Localize("#round") + " " + num)
}

function RoundCountdown() {
	round = CustomNetTables.GetTableValue("gamestate", "round")["1"]
	nextround = round + 1
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

function EndGame() {
	var value = CustomNetTables.GetTableValue("gamestate", "winning_team")
	var team = parseInt(value["1"])
	var details = Game.GetTeamDetails(team)
	var winner = ""
	if ( details.team_num_players == 1) {
		winner = Players.GetPlayerName(Game.GetPlayerIDsOnTeam(team)[0])
	} else {
		winner = details.team_name
	}
	$("#winner").text = winner + " " + $.Localize("#wins")
	$("#winner").style.visibility = "visible"
	$("#rematch").text = $.Localize("#rematch_question")
	$("#rematch").style.visibility = "visible"
	$("#rematch-buttons").style.visibility = "visible"
	$("#gameover").style.visibility = "visible"
}

function Rematch() {
	$("gameover").style.visibility = "collapse"
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
	$("rematch").text = $.Localize("#rematch_declined")
	$("#rematch-buttons").style.visibility = "collapse"
}

(function()
{
	CustomNetTables.SubscribeNetTableListener("gamestate", CheckGamestate)
	GameEvents.Subscribe("rematch_no", OnRematchNo)
})();