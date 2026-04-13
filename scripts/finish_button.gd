extends StaticBody3D

@export var next_scene: PackedScene
@export var level_id: String

func _interact():
	var player     = get_tree().get_first_node_in_group("player")
	var timer      = player.speedrun_timer
	var ui         = player.get_node("UI")
	var lvl_screen = player.get_node("LevelCompleteCanvasLayer/LevelComplete")
	$Success.play()

	timer.stop()
	ui.hide()
	lvl_screen.show_complete(timer._elapsed, level_id, next_scene)
