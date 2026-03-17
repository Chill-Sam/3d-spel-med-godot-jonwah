extends Enemy


func _ready() -> void:
	super()
	health = 15.0
	max_health = 15.0


func _physics_process(delta: float) -> void:
	if not player:
		return

	nav_agent.target_position = player.global_position

	var distance = global_position.distance_to(player.global_position)

	if distance <= attack_range:
		try_attack()
	else:
		move_towards_player()
		
	if nav_agent.is_navigation_finished():
		return

	super(delta)


func move_towards_player() -> void:
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity = direction * speed


func try_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	attack()
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func attack() -> void:
	if player.has_method("damage"):
		player.damage(attack_damage)


func die() -> void:
	queue_free()
