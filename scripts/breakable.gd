extends StaticBody3D

@onready var shatter: AudioStreamPlayer3D = $Shatter

var broken := false

func _ready():
	for shard in $VoronoiShatter/Fractured.get_children():
		shard.hide()
		shard.freeze = true

func _break(hit_position: Vector3):
	if broken:
		return
	broken = true
	$VoronoiShatter/MeshInstance3D.hide()
	$CollisionShape3D.disabled = true
	shatter.play()

	for shard in $VoronoiShatter/Fractured.get_children():
		shard.show()
		shard.freeze = false
		shard.collision_layer = 0

		# Impulse away from hit point
		var dir = (shard.global_position - hit_position).normalized()
		dir += Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.4), randf_range(-0.2, 0.2))
		shard.apply_central_impulse(dir * 2.0)
		shard.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 1.5)

		# Clean up after a few seconds
		get_tree().create_timer(randf_range(5.0, 10.0)).timeout.connect(shard.queue_free)
