extends Node

const SAVE_PATH := "user://save.cfg"

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(SAVE_PATH)


func get_best_time(level_id: String) -> float:
	return _config.get_value("times", level_id, -1.0)  # -1 = no time saved yet


func submit_time(level_id: String, time: float) -> void:
	var best: float = get_best_time(level_id)
	if best < 0.0 or time < best:
		_config.set_value("times", level_id, time)
		_config.save(SAVE_PATH)
