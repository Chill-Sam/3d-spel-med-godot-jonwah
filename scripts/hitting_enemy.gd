extends Enemy

@onready var eyes = $Eyes
@onready var anim_tree = $AnimationTree
@onready var state: AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]
@onready var damage_sound: AudioStreamPlayer3D = $DamageSound

var is_chasing = false
var is_dead = false

func _physics_process(delta: float) -> void:
	super(delta)
		
	if is_dead:
		return
		
	if velocity.length() < 0.5:
		state.travel("Idle")
	else:
		state.travel("Run")
		
	eyes.target_position = to_local(player.global_position)
	if (eyes.is_colliding() and eyes.get_collider() == player):
		is_chasing = true
	else:
		pass
		
	if not is_chasing:
		velocity = Vector3.ZERO
		super(delta)
		return

	nav_agent.target_position = player.global_position

	var distance = global_position.distance_to(player.global_position)
	_face_player()
	if distance <= attack_range:
		try_attack()
	else:
		move_towards_player()
		
	if nav_agent.is_navigation_finished():
		return



func move_towards_player() -> void:
	var next_pos = nav_agent.get_next_path_position()
	var direction = Vector3((next_pos - global_position).x, velocity.y, (next_pos - global_position).z).normalized()
	velocity = direction * speed


func try_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	state.travel("Punch")
	attack()
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func attack() -> void:
	if player.has_method("damage"):
		player.damage(attack_damage)


func die() -> void:
	remove_from_group("enemy")
	collision_layer &= ~4
	collision_mask &= ~2
	is_dead = true
	state.travel("Death")

func damage(dmg: float) -> void:
	damage_sound.play()
	super(dmg)

func _face_player() -> void:
	var look_target       := player.global_position
	look_target.y          = global_position.y
	if global_position.distance_squared_to(look_target) > 0.001:
		look_at(look_target, Vector3.UP)
