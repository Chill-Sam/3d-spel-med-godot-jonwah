extends Node3D

@onready var exit_door: StaticBody3D = $NavigationRegion3D/Level1_Map/Map/Props/ExitDoor

var exit_open = false

func _process(delta: float) -> void:
	var count = get_tree().get_nodes_in_group("enemy").size()
	if (not exit_open and count == 0):
		exit_open = true
		exit_door.queue_free()
