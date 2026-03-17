@abstract class_name Enemy extends CharacterBody3D

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

var player: Node3D
var nav_agent: NavigationAgent3D
var can_attack: bool = true

func _ready() -> void:
	nav_agent = $NavigationAgent3D
	player = get_tree().get_first_node_in_group("player")
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func damage(damage: float) -> void:
	health -= damage
	if health <= 0:
		die()


@abstract func die() -> void
