function SplitUnitClicked() {
	var ent = $.GetContextPanel().GetAttributeInt("entindex", -1)
	if (Entities.IsSelectable(ent)) {
		GameUI.SelectUnit(ent, false)
	}
}

function SplitUnitDoubleClicked() {
	var ent = $.GetContextPanel().GetAttributeInt("entindex", -1)
	if (Entities.IsSelectable(ent)) {
		GameEvents.SendCustomGameEventToServer("move_camera", {target: ent})
	}
}

function UpdateHealthBar() {
	var panel = $.GetContextPanel()
	var pct = Entities.GetHealthPercent(panel.GetAttributeInt("entindex", -1))
	var fill_bar = panel.FindChildrenWithClassTraverse("health_bar_fill")[0]
	if (fill_bar != null) {
		fill_bar.style.width = pct.toString() + "%"
	}
	$.Schedule(0.03, UpdateHealthBar)
}

(function()
{
	UpdateHealthBar()
})()