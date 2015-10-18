function UpdateAbilityCooldown() {
	var ability = $.GetContextPanel().GetAttributeInt("ability_entindex", -1)
	$.GetContextPanel().SetHasClass("cooldown", !Abilities.IsCooldownReady(ability))
	$.Schedule(0.03, UpdateAbilityCooldown)
}

function OnSplitAbilityClicked() {
	var panel = $.GetContextPanel()
	var unit = panel.GetAttributeInt("unit_entindex", -1)
	var ability = panel.GetAttributeInt("ability_entindex", -1)
	if (Entities.IsSelectable(unit)) {
		GameUI.SelectUnit(unit, false)
		Abilities.ExecuteAbility(ability, unit, false)
	}
}

function OnMouseover() {
	$.DispatchEvent("DOTAShowAbilityTooltip", $.GetContextPanel(), $.GetContextPanel().Children(0)[0].Children(0)[0].abilityname)
}

function OnMouseout() {
	$.DispatchEvent("DOTAHideAbilityTooltip")
}

(function()
{
	UpdateAbilityCooldown()
})() 