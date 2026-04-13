extends Control

func _ready() -> void:
	hide()
	$CenterContainer/VBoxContainer/MarginContainer/RetryButton.pressed.connect(_on_retry)
	$CenterContainer/VBoxContainer/MarginContainer2/QuitButton.pressed.connect(_on_quit)


func show_death() -> void:
	get_tree().paused = true
	Engine.time_scale  = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
