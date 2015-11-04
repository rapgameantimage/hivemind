"use strict";
 
var POST_ROUND_DELAY = 5
var END_GAME_DELAY = 2

var next_countdown
var round = 0
var nextround

var dont_show_tips_for = []

function OnRoundStarted(event) { 
	var num = CustomNetTables.GetTableValue("gamestate", "round")["1"]
	$("#pick").style.visibility = "collapse"
	$("#pick-status").style.visibility = "collapse"
	SetAlert(5, $.Localize("#round") + " " + num)
}

function OnRoundCompleted(event) {
	$.Msg("OnRoundCompleted")
	$("#pick").style.visibility = "collapse"
	$("#pick-status").style.visibility = "collapse"
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
	var win_msg = ""
	if ( details.team_num_players == 1) {
		win_msg = Players.GetPlayerName(Game.GetPlayerIDsOnTeam(team)[0]) + " " + $.Localize("#wins")
	} else {
		win_msg = Players.GetPlayerName(Game.GetPlayerIDsOnTeam(team)[0]) + " " + $.Localize("#and") + " " + Players.GetPlayerName(Game.GetPlayerIDsOnTeam(team)[1]) + " " + $.Localize("#win")
	}
	$.Schedule(END_GAME_DELAY, function() {
		$("#winner").text = win_msg
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

function OnRematchDeclined() {
	$("#rematch").text = $.Localize("#rematch_declined")
	$("#winner").style.visibility = "collapse"
	$("#rematch-buttons").style.visibility = "collapse"
	$.Schedule(3, function() {
		$("#gameover").style.visibility = "collapse"
	})
}
 
function CreatePickBoard() {
	$("#pick-wrapper").Children(0).RemoveAndDeleteChildren
	$.CreatePanel("Panel", $("#pick-wrapper"), "pick")
	$("#pick").BLoadLayout("file://{resources}/layout/custom_game/pick_board.xml", false, false)

	$("#pick-status-body").RemoveAndDeleteChildren()
	var teams = [DOTATeam_t.DOTA_TEAM_GOODGUYS, DOTATeam_t.DOTA_TEAM_BADGUYS]
	for (var i in teams) {
		var players = Game.GetPlayerIDsOnTeam(teams[i])
		for (var j in players) { 
			var player = players[j]
			var panel = $.CreatePanel("Panel", $("#pick-status-body"), "pick-status-player-" + player)
			panel.SetAttributeInt("player", player)
			panel.BLoadLayout("file://{resources}/layout/custom_game/pick_status_player.xml", false, false)
			panel.GetChild(0).text = Players.GetPlayerName(player)
			$.Msg(Players.GetPlayerName(player))
		}
	}
	$("#pick-status").style.visibility = "visible"
}

function OnMatchStarted() {
//	$("#pick").style.visibility = "collapse"
}

function OnEntityKilled(event) {
	var entity_killed = event.entindex_killed
	var attacker = event.entindex_attacker

	// See if this is the player.
	var localhero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())
	if (entity_killed == localhero && entity_killed != attacker) {
		// Find the enemy hero and show the tip screen (if the player has hidden tip screens, that is taken care of in the ShowTipsFor function)
		var localteam = Entities.GetTeamNumber(localhero)
		var enemyhero

		if (Entities.IsHero(attacker)) {
			enemyhero = attacker
		} else {
			var enemyteam = 0
			if (localteam == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
				enemyteam = DOTATeam_t.DOTA_TEAM_BADGUYS
			} else if (localteam == DOTATeam_t.DOTA_TEAM_BADGUYS) {
				enemyteam = DOTATeam_t.DOTA_TEAM_GOODGUYS
			}
			var enemyplayers = Game.GetPlayerIDsOnTeam(enemyteam)
			for (var i = 0; i < enemyplayers.length; i++) {
				var units = CustomNetTables.GetTableValue("split_units", Players.GetPlayerHeroEntityIndex(enemyplayers[i]).toString())
				$.Each(units, function(j,v) {
					if (parseInt(v) == attacker) {
						enemyhero = Players.GetPlayerHeroEntityIndex(enemyplayers[i])
					}
				})
			}
		}

		if (enemyhero) {
			ShowTipsFor(Entities.GetClassname(enemyhero))
		}
	}

	// Deselects killed units from multi-select groups, so the player's commands don't keep getting delivered to a dead unit
	// First, see if the dead unit is selected
	var selection = Players.GetSelectedEntities(Players.GetLocalPlayer())
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

function ShowTipsFor(hero) {
	if (dont_show_tips_for.indexOf(hero) == -1) { 
		$("#tips").SetAttributeString("hero", hero)
		$("#tips-header").text = $.Localize("#tips_header") + " " + $.Localize("#" + hero)
		var shortname = hero.substring(14)		// strip "npc_dota_hero_"
		for (var i = 1; i <= 3; i++) {
			// see if this tip exists and assign it if it does
			var try_localize = $.Localize("#tips_vs_" + shortname + "_" + i)
			if (try_localize === "tips_vs_" + shortname + "_" + i || try_localize === "")
			{
				$("#tip-" + i).text = ""
			} else {
				$("#tip-" + i).text = "+ " + try_localize
			}
		}
		$("#tips-heroimage").heroname = hero
		$("#tips-dont-show-again").checked = false
		$("#tips").style.visibility = "visible"
		$("#tips").SetHasClass("hidden", false)
	}
}

function CloseTips() {
	$("#tips").style.visibility = "collapse"
	$("#tips").SetHasClass("hidden", true)
	if ($("#tips-dont-show-again").checked) {
		dont_show_tips_for.push($("#tips").GetAttributeString("hero", "na"))
	}
}

function OnSplitHeroFinished() {
	var units = CustomNetTables.GetTableValue("split_units", Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()).toString())
	var first = true
	for (var unit in units) {
		unit = parseInt(unit)
		GameUI.SelectUnit(unit, !first)
		first = false
	}
}
  
function OnItemWillSpawn(event) {
	SetAlert(3, PrefixSingularArticle($.Localize("DOTA_Tooltip_ability_" + event.item)) + " " + $.Localize("#will_spawn"))
}

function OnItemHasSpawned(event) {
	SetAlert(3, PrefixSingularArticle($.Localize("DOTA_Tooltip_ability_" + event.item)) + " " + $.Localize("#has_spawned"))
}

function PrefixSingularArticle(thing) {
	if ("aeiou".indexOf(thing.charAt(0)) != -1) {
		return "An " + thing
	} else {
		return "A " + thing 
	}
}

function OnGamestateChange(table, key, value) {
	if (key === "new_hero_picks") {
		$.Each(value, function(hero, player) {
			var panels = $("#pick-status-body").Children()
			for (var i in panels) {
				var panel = panels[i]
				if (panel.GetAttributeInt("player", -1) == player) {
					panel.SetHasClass("picked", true)
				}
			}
		})
	}
}
 
(function()
{
	CreatePickBoard()

	GameEvents.Subscribe("rematch_declined", OnRematchDeclined)
	GameEvents.Subscribe("rematch_accepted", OnRematchAccepted)
	GameEvents.Subscribe("round_started", OnRoundStarted)
	GameEvents.Subscribe("round_completed", OnRoundCompleted)
	GameEvents.Subscribe("match_started", OnMatchStarted)
	GameEvents.Subscribe("match_completed", OnMatchCompleted)
	GameEvents.Subscribe("entity_killed", OnEntityKilled)
	GameEvents.Subscribe("arena_shrink", OnArenaShrink)
	GameEvents.Subscribe("split_hero_finished", OnSplitHeroFinished)
	GameEvents.Subscribe("item_will_spawn", OnItemWillSpawn)
	GameEvents.Subscribe("item_has_spawned", OnItemHasSpawned)
	CustomNetTables.SubscribeNetTableListener("gamestate", OnGamestateChange)
})();
