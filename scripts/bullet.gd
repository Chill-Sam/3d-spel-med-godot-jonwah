extends CharacterBody3D

@onready var bullet_hole_scene: PackedScene = preload("res://scenes/bullet_hole.tscn")

var damage: float = 15.0
var speed: float = 70.0
var lifetime: float = 3.0

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.has_method("damage"):
			collider.damage(damage)
		elif collider.has_method("_break"):
			collider._break(global_position);
		else:
			spawn_decal(collision)
		queue_free()

func spawn_decal(collision: KinematicCollision3D) -> void:
	var hole = bullet_hole_scene.instantiate()
	get_tree().root.add_child(hole)
	
	hole.global_position = collision.get_position() + collision.get_normal() * 0.001
	hole.look_at(hole.global_position - collision.get_normal(), Vector3.FORWARD)
	hole.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	get_tree().create_timer(5).timeout.connect(hole.queue_free)
