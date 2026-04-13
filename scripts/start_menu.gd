extends Control

@onready var main_panel: PanelContainer = $MainPanel
@onready var help_overlay: PanelContainer = $HelpOverlay
@onready var level_container: PanelContainer = $LevelContainer

const LEVELS := [
	{ "id": "level_1", "scene": "res://scenes/level_1.tscn", "label": "Trial 1" },
	{ "id": "level_2", "scene": "res://scenes/level_2.tscn", "label": "Trial 2" },
	{ "id": "level_3", "scene": "res://scenes/level_3.tscn", "label": "Trial 3" },
]

@onready var play_buttons := [
	$LevelContainer/CenterContainer/VBoxContainer/LevelRow1/PlayBtn1,
	$LevelContainer/CenterContainer/VBoxContainer/LevelRow2/PlayBtn2,
	$LevelContainer/CenterContainer/VBoxContainer/LevelRow3/PlayBtn3,
]
@onready var time_labels := [
	$LevelContainer/CenterContainer/VBoxContainer/LevelRow1/Time1,
	$LevelContainer/CenterContainer/VBoxContainer/LevelRow2/Time2,
	$LevelContainer/CenterContainer/VBoxContainer/LevelRow3/Time3,
]


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	for i in LEVELS.size():
		var idx := i  # capture for lambda
		play_buttons[i].text = LEVELS[i]["label"]
		play_buttons[i].pressed.connect(func(): _on_play(idx))
		_refresh_time(i)
		
	help_overlay.hide()
	level_container.hide()
	main_panel.show()

	$MainPanel/CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_menu)
	$MainPanel/CenterContainer/VBoxContainer/HelpButton.pressed.connect(_on_help)
	$MainPanel/CenterContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit)
	$HelpOverlay/CenterContainer/VBoxContainer/CloseButton.pressed.connect(_on_close_help)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and help_overlay.visible:
		_on_close_help()
		
	if event.is_action_pressed("ui_cancel") and level_container.visible:
		level_container.hide()
		main_panel.show()

func _refresh_time(i: int) -> void:
	var best: float = SaveData.get_best_time(LEVELS[i]["id"])
	time_labels[i].text = "Best: " + (_format(best) if best >= 0.0 else "--:--.---")

func _on_play(i: int) -> void:
	get_tree().change_scene_to_file(LEVELS[i]["scene"])

func _on_menu() -> void:
	main_panel.hide()
	level_container.show()

func _on_help() -> void:
	main_panel.hide()
	help_overlay.show()

func _on_exit() -> void:
	get_tree().quit()


func _on_close_help() -> void:
	help_overlay.hide()
	main_panel.show()
	
func _format(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var millis  := int(fmod(t, 1.0) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]
