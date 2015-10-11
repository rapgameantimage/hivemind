"use strict"

function OnMouseover() {
	$.DispatchEvent("DOTAShowAbilityTooltip", $.GetContextPanel(), $.GetContextPanel().Children(0)[0].abilityname)
}

function OnMouseout() {
	$.DispatchEvent("DOTAHideAbilityTooltip")
}