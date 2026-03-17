class_name Gun extends Item

@onready var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var raycast: RayCast3D

func _ready() -> void:
	# Walk up to Camera3D, then get the RayCast3D from there
	raycast = get_parent().get_parent().get_node("Aim")

func use() -> void:
	raycast.force_raycast_update()

	var aim_point: Vector3
	if raycast.is_colliding():
		aim_point = raycast.get_collision_point()
	else:
		# Nothing hit, aim at far point along ray
		aim_point = raycast.global_position + (-raycast.global_transform.basis.z * 1000.0)

	var bullet = bullet_scene.instantiate()
	bullet.velocity = (aim_point - global_position).normalized() * bullet.speed
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
