extends Control

var _next_scene: PackedScene = null
var _level_id: String = ""

func _ready() -> void:
	hide()
	$CenterContainer/VBoxContainer/MarginContainer2/NextButton.pressed.connect(_on_next)
	$CenterContainer/VBoxContainer/MarginContainer3/QuitButton.pressed.connect(_on_quit)


func show_complete(time: float, level_id: String, next_scene: PackedScene) -> void:
	_next_scene = next_scene
	_level_id = level_id
	
	var previous_best: float = SaveData.get_best_time(level_id)
	var is_record: bool = previous_best < 0.0 or time < previous_best
	
	SaveData.submit_time(level_id, time)
	$CenterContainer/VBoxContainer/MarginContainer/TimeLabel.text = "Time: " + _format(time)
	$Record.visible = is_record
	
	get_tree().paused = true
	Engine.time_scale  = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()


func _on_next() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(_next_scene)


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _format(t: float):
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var millis  := int(fmod(t, 1.0) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]
