extends Control

@onready var main_panel: PanelContainer = $MainPanel
@onready var help_overlay: PanelContainer = $HelpOverlay

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	help_overlay.hide()
	main_panel.show()

	$MainPanel/CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play)
	$MainPanel/CenterContainer/VBoxContainer/HelpButton.pressed.connect(_on_help)
	$MainPanel/CenterContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit)
	$HelpOverlay/CenterContainer/VBoxContainer/CloseButton.pressed.connect(_on_close_help)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and help_overlay.visible:
		_on_close_help()


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_help() -> void:
	main_panel.hide()
	help_overlay.show()

func _on_exit() -> void:
	get_tree().quit()


func _on_close_help() -> void:
	help_overlay.hide()
	main_panel.show()
