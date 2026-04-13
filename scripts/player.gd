class_name Player
extends CharacterBody3D

@onready var camera = $Camera3D
@onready var arm_camera = $GunViewport/SubViewport/Camera3D
@onready var standing_collision = $StandingCollision
@onready var crouching_collison = $CrouchingCollision
@onready var mesh = $Body
@onready var shadow = $Shadow
@onready var roof_raycast_1 = $RoofRaycast1
@onready var roof_raycast_2 = $RoofRaycast2
@onready var roof_raycast_3 = $RoofRaycast3
@onready var roof_raycast_4 = $RoofRaycast4
@onready var gun_anim_tree = $GunAnimations
@onready var gun_sm = gun_anim_tree.get("parameters/playback")
@onready var gun = $Camera3D/Pivot/Gun
@onready var health_bar: TextureProgressBar = $UI/Health/HealthProgress
@onready var stamina_bar: TextureProgressBar = $UI/Health/StaminaProgress
@onready var right_wall_cast: RayCast3D = $RightWallCast
@onready var left_wall_cast: RayCast3D = $LeftWallCast
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var death_screen = $CanvasLayer2/DeathScreen
@onready var interact = $Camera3D/Interact
@onready var speedrun_timer = $UI/TimerLabel
@onready var gunshot: AudioStreamPlayer3D = $Gunshot
@onready var damage_sound: AudioStreamPlayer3D = $Damage
@onready var footstep: AudioStreamPlayer3D = $Footstep

@export var slow_time_scale:       float = 0.4
@export var stamina_max:           float = 5.0
@export var stamina_drain_rate:    float = 1.0
@export var stamina_regen_rate:    float = 0.4
@export var stamina_recover_threshold: float = 0.5
@export var sensitivity = 0.003
@export var fire_rate: float = 0.75

const CROUCH_SPEED := 2.0
const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const AIR_SPEED := 7.5
const JUMP_SPEED := 5.0
const ACCEL := 15.0
const DECEL := 45.0
const SLIDE_ACCEL := 5.0
const SLIDE_DECEL := 2.5
const AIR_ACCEL := 10.0
const AIR_DECEL := 5.0
const WALL_PUSH := 6.0
const WALL_TILT_ANGLE := 0.15  # radians, ~8.5 degrees

var health = 100.0
var max_health = 100.0
var passive_regen = 2.5
var _stamina:      float = stamina_max
var _slow_active:  bool  = false
var _exhausted:   bool  = false

var footstep_timer := 0.0
var footstep_interval := 0.3

var current_tilt := 0.0
var fov_tween: Tween
var camera_rotation = Vector2(0, 0)
var is_crouching := false
var cur_speed := WALK_SPEED
var _can_fire: bool = true
var is_dead: bool = false
var is_wallrunning: bool = false


func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$RegenTimer.timeout.connect(
		func():
			health = clamp(health + passive_regen, 0, max_health)
	)
	
	global_position = get_node("%Spawnpoint").global_position


func _process(_delta: float) -> void:
	arm_camera.global_transform = camera.global_transform


func _input(event: InputEvent) -> void:
	if is_dead:
		return
	
	if event.is_action_pressed("ui_cancel"):
		pause_menu._set_paused(true)
		return  # swallow the event

	if event is InputEventMouseMotion:
		var mouseEvent = event.relative * sensitivity
		_camera_look(mouseEvent)


func _camera_look(Movement: Vector2):
	camera_rotation += Movement
	camera_rotation.y = clamp(camera_rotation.y, -1.5, 1.2)

	transform.basis = Basis()
	camera.transform.basis = Basis()

	rotate_object_local(Vector3(0, 1, 0), -camera_rotation.x)
	camera.rotate_object_local(Vector3(1, 0, 0), -camera_rotation.y)
	camera.rotation.z = current_tilt  # re-apply tilt to not cause camera jitter

func _set_crouch(crouch: bool, delta: float) -> void:
	if is_crouching == crouch:
		return

	if (
		is_crouching and (
			roof_raycast_1.is_colliding() or
			roof_raycast_2.is_colliding() or
			roof_raycast_3.is_colliding() or
			roof_raycast_4.is_colliding()
		)
	):
		return

	is_crouching = crouch

	standing_collision.disabled = crouch
	crouching_collison.disabled = not crouch

	if is_crouching and is_on_floor():
		velocity.y = -20.0
	elif !is_crouching and is_on_floor():
		position.y += 0.2
		
	var target_y := 0.0 if crouch else 0.8
	camera.position.y = lerp(camera.position.y, target_y, 12.0 * delta)


func _set_fov_smooth(new_fov: float, duration: float = 0.25) -> void:

	if fov_tween and fov_tween.is_running():
		fov_tween.kill()

	fov_tween = create_tween()
	fov_tween.tween_property(camera, "fov", new_fov, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_wall_tilt(delta: float) -> void:
	var target_tilt := 0.0
	
	if is_wallrunning and not is_on_floor():
		if right_wall_cast.is_colliding():
			target_tilt = WALL_TILT_ANGLE
		elif left_wall_cast.is_colliding():
			target_tilt = -WALL_TILT_ANGLE
	
	current_tilt = lerp(current_tilt, target_tilt, 10.0 * delta)
	camera.rotation.z = current_tilt


func _animate() -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	var t = clamp(speed / RUN_SPEED, 0.0, 1.0)
	gun_anim_tree.set("parameters/Locomotion/blend_position", t)

	if !is_on_floor() and (
		gun_sm.get_current_node() != "Jump" and gun_sm.get_current_node() != "Shoot"
	) and not is_wallrunning and not is_crouching:
		gun_sm.travel("Jump")

	if (is_on_floor() or is_wallrunning) and gun_sm.get_current_node() != "Locomotion":
		gun_sm.travel("Locomotion")


func _shoot() -> void:
	if not _can_fire:
		return

	_can_fire = false

	gun.use()

	if gun_sm.get_current_node() == "Shoot":
		gun_sm.start("Shoot")
	else:
		gun_sm.travel("Shoot")
		
	gunshot.play()

	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true


func _physics_process(delta: float) -> void:
	if is_dead:
		print("DEAD")

	if (Input.is_action_pressed("ui_left")  or
	   Input.is_action_pressed("ui_right") or
	   Input.is_action_pressed("ui_up")    or
	   Input.is_action_pressed("ui_down")  or
	   Input.is_action_just_pressed("jump")):
		speedrun_timer.start()

	_update_slow_mo(delta)

	health_bar.value = health
	stamina_bar.value = _stamina

	is_wallrunning = (right_wall_cast.is_colliding() or left_wall_cast.is_colliding()) and (velocity.x ** 2 + velocity.z ** 2) > 4.0
	if not is_on_floor():
		var gravity_scale = 0.1 if is_wallrunning and velocity.y < 0 else 1.0 
		velocity += get_gravity() * delta * gravity_scale

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_SPEED
		gun_sm.travel("Jump")

	if Input.is_action_just_pressed("shoot"):
		_shoot()
	
	if Input.is_action_just_pressed("interact"):
		if (interact.is_colliding()):
			var obj = interact.get_collider()
			if (obj.has_method("_interact")):
				obj._interact()
			

	if Input.is_action_pressed("crouch"):
		_set_crouch(true, delta)
		mesh.scale.y = 0.8 / 1.8
		shadow.scale.y = 0.8 / 1.8
	else:
		_set_crouch(false, delta)
		mesh.scale.y = 1.0
		shadow.scale.y = 1.0

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wish_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	cur_speed = (
		AIR_SPEED if not is_on_floor() and not is_wallrunning else
		CROUCH_SPEED if is_crouching else
		RUN_SPEED if Input.is_action_pressed("sprint") else
		WALK_SPEED
	)

	var target_hvel := wish_dir * cur_speed

	var hvel := Vector3(velocity.x, 0.0, velocity.z)

	var accel := (
		SLIDE_ACCEL if is_crouching and hvel.length() >= 3.0 else
		ACCEL if is_on_floor() or is_wallrunning else
		AIR_ACCEL
	)
	var decel := (
		SLIDE_DECEL if is_crouching and hvel.length() >= 3.0 else
		DECEL if is_on_floor() or is_wallrunning else
		AIR_DECEL
	)

	if wish_dir != Vector3.ZERO:
		hvel = hvel.move_toward(target_hvel, accel * delta)
	else:
		hvel = hvel.move_toward(Vector3.ZERO, decel * delta)

	velocity.x = hvel.x
	velocity.z = hvel.z

	# Zero velocity perpendicular to wall
	if is_wallrunning and not is_on_floor():
		for raycast in [left_wall_cast, right_wall_cast]:
			if raycast.is_colliding():
				var wall_normal: Vector3 = raycast.get_collision_normal()
				if Input.is_action_just_pressed("jump"):
					velocity += wall_normal * WALL_PUSH
					# Forward along wall (cross with up to get wall-parallel direction)
					var along_wall: Vector3 = wall_normal.cross(Vector3.UP).normalized()
			
					if along_wall.dot(velocity) < 0:
						along_wall = -along_wall
			
					velocity += along_wall * WALL_PUSH * 0.8
					break
					
				# Remove the component of velocity pointing into the wall
				velocity -= wall_normal * wall_normal.dot(velocity)
	

	move_and_slide()
	
	if velocity.length() > 0.1:
		footstep_timer -= delta
		if footstep_timer <= 0.0 and (is_on_floor() or is_wallrunning) and not (is_crouching and hvel.length() >= 3.0):
			play_footstep()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0 
	
	_update_wall_tilt(delta)
	_animate()
	_set_fov_smooth(90 + 20 * velocity.length() / RUN_SPEED)


func _update_slow_mo(delta: float) -> void:
	# Unscaled delta so stamina always moves in real time.
	var real_delta: float = delta / Engine.time_scale

	if _stamina <= 0.0:
		_exhausted = true
	elif _stamina >= stamina_recover_threshold:
		_exhausted = false

	var wants_slow: bool = Input.is_action_pressed("slow_mo") and not _exhausted
	
	if wants_slow:
		_stamina -= stamina_drain_rate * real_delta
		_stamina  = maxf(_stamina, 0.0)
		_slow_active = true
	else:
		_stamina += stamina_regen_rate * real_delta
		_stamina  = minf(_stamina, stamina_max)
		_slow_active = false

	Engine.time_scale = slow_time_scale if _slow_active else 1.0

func damage(dmg: float):
	damage_sound.play()
	health -= dmg
	if health <= 0:
		die()


func play_footstep():
	# pick a random sound so it doesn't sound robotic
	#footstep_player.stream = footstep_sounds.pick_random()
	footstep.pitch_scale = randf_range(0.9, 1.1)  # slight pitch variation
	footstep.play()

func die():
	is_dead = true
	death_screen.show_death()
