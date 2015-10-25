function OnIconClicked() {
	var hero = $.GetContextPanel().GetChild(0).GetAttributeInt("hero", -1)
	if (hero != -1) {
		if (Entities.IsControllableByPlayer(hero, Players.GetLocalPlayer()) && Entities.IsSelectable(hero)) {
			GameUI.SelectUnit(hero, false)
		}
	}
}

function OnIconDoubleClicked() {
	var hero = $.GetContextPanel().GetChild(0).GetAttributeInt("hero", -1)
	if (hero != -1) {
		if (Entities.IsControllableByPlayer(hero, Players.GetLocalPlayer()) && Entities.IsSelectable(hero)) {
			GameEvents.SendCustomGameEventToServer("move_camera", {target: hero})
		}
	}
}