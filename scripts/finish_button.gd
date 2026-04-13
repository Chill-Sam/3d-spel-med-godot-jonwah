extends StaticBody3D

@export var next_scene: PackedScene

func _interact():
	var player     = get_tree().get_first_node_in_group("player")
	var timer      = player.speedrun_timer
	var ui         = player.get_node("UI")
	var lvl_screen = player.get_node("LevelCompleteCanvasLayer/LevelComplete")

	timer.stop()
	ui.hide()
	lvl_screen.show_complete(timer._elapsed, next_scene)
