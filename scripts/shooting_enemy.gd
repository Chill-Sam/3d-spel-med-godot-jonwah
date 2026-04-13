class_name ShootingEnemy extends Enemy

@export var bullet_scene:       PackedScene
@export var preferred_distance: float = 8.0   ## Tries to stay at this range
@export var too_close_distance: float = 4.0   ## Backs away below this

@onready var los_ray: RayCast3D = $LosRay
@onready var muzzle: Marker3D = $"Ch15_nonPBR/GeneralSkeleton/BoneAttachment3D/blaster-f/MuzzlePoint"

@onready var anim_tree = $AnimationTree
@onready var state: AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]
@onready var damage_sound: AudioStreamPlayer3D = $DamageSound

var _shoot_cooldown: float = 0.0
var is_dead = false

func _physics_process(delta: float) -> void:
	super(delta)
	
	if is_dead:
		return
	
	if velocity.length() < 0.2:
		state.travel("Idle")
	else:
		state.travel("Run")
	
	if not _has_line_of_sight():
		return
	
	_update_movement()
	_update_shooting(delta)

func _update_movement() -> void:
	var dist: float = global_position.distance_to(player.global_position)

	if dist < too_close_distance:
		_flee()
	elif dist > preferred_distance:
		_navigate_toward_player()
	else:
		# In the preferred band — hold position, just face the player.
		velocity.x = 0.0
		velocity.z = 0.0

	_face_player()


func _flee() -> void:
	var flee_dir := (global_position - player.global_position)
	flee_dir.y = 0.0
	flee_dir   = flee_dir.normalized()
	velocity.x = flee_dir.x * speed
	velocity.z = flee_dir.z * speed


func _navigate_toward_player() -> void:
	nav_agent.set_target_position(player.global_position)

	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var next_pos  := nav_agent.get_next_path_position()
	var move_dir  := global_position.direction_to(next_pos)
	move_dir.y    =  0.0
	move_dir      =  move_dir.normalized()
	velocity.x    =  move_dir.x * speed
	velocity.z    =  move_dir.z * speed


func _face_player() -> void:
	var look_target       := player.global_position
	look_target.y          = global_position.y
	if global_position.distance_squared_to(look_target) > 0.001:
		look_at(look_target, Vector3.UP)


func _update_shooting(delta: float) -> void:
	_shoot_cooldown -= delta
	if _shoot_cooldown > 0.0:
		return

	if global_position.distance_to(player.global_position) > attack_range:
		return

	_fire()
	_shoot_cooldown = attack_cooldown


func _has_line_of_sight() -> bool:
	los_ray.target_position = los_ray.to_local(player.global_position)

	if not los_ray.is_colliding():
		return true

	return los_ray.get_collider() == player


func _fire() -> void:
	state.travel("Shoot")
	
	var bullet := bullet_scene.instantiate()
	bullet.damage = attack_damage # Make it easier for player :D
	bullet.velocity = (player.global_position - muzzle.global_position).normalized() * bullet.speed
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle.global_transform

func die() -> void:
	collision_layer &= ~4
	collision_mask &= ~2
	remove_from_group("enemy")
	is_dead = true
	state.travel("Death")

func damage(dmg: float) -> void:
	damage_sound.play()
	super(dmg)
