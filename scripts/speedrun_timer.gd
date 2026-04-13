extends Label

var _elapsed:  float = 0.0
var _running:  bool  = false
var _finished: bool  = false


func _process(delta: float) -> void:
	if _running and not _finished:
		_elapsed += delta
		text = _format(_elapsed)


func start() -> void:
	if _running or _finished:
		return
	_running = true


func stop() -> void:
	_running  = false
	_finished = true


func _format(t: float):
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var millis  := int(fmod(t, 1.0) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]
