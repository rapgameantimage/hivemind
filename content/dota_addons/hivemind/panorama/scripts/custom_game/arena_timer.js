"use strict"

function OnArenaShrinkTick(event) {
	$("#arena_timer_fill").style.width = (event.percent_elapsed * 100).toString() + "%"
}

(function() {
	GameEvents.Subscribe("arena_shrink_tick", OnArenaShrinkTick)
})()