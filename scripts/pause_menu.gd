extends Control

func _ready() -> void:
	hide()
	$CenterContainer/VBoxContainer/MarginContainer/ResumeButton.pressed.connect(_on_resume)
	$CenterContainer/VBoxContainer/MarginContainer2/QuitButton.pressed.connect(_on_quit)


func _on_resume() -> void:
	_set_paused(false)


func _on_quit() -> void:
	_set_paused(false)
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	Engine.time_scale  = 1.0   # reset slow-mo if it was active
	visible            = paused
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	)
