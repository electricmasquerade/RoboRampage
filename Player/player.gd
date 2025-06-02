extends CharacterBody3D
class_name Player

@export var SPEED = 5.0
@export var sensitivity = 100
@export var jump_height := 1.0
@export var fall_multiplier := 2.0
@export var max_hitpoints := 100
@export var aim_multiplier := 0.7

@onready var ammo_handler: AmmoHandler = %AmmoHandler
@onready var camera_pivot: Node3D = $CameraPivot
@onready var damage_animation_player: AnimationPlayer = $DamageTexture/DamageAnimationPlayer
@onready var game_over_menu: Control = $GameOverMenu
@onready var smooth_camera: Camera3D = %SmoothCamera
@onready var smooth_camera_fov := smooth_camera.fov
@onready var weapon_camera: Camera3D = %WeaponCamera
@onready var weapon_camera_fov := weapon_camera.fov

var aiming := false

var hitpoints := max_hitpoints:
	set(value):
		if value <= hitpoints:
			damage_animation_player.stop(false)
			damage_animation_player.play("TakeDamage")
		hitpoints = value
		
		if hitpoints <= 0:
			game_over_menu.game_over()
	get:
		return hitpoints
var mouse_motion := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if Input.is_action_pressed("aim"):
		aiming = true
		smooth_camera.fov = lerp(
			smooth_camera.fov,
			aim_multiplier * smooth_camera_fov, 
			delta * 20
			)
		weapon_camera.fov = lerp(
			weapon_camera.fov,
			aim_multiplier * weapon_camera_fov,
			delta*20
			)
	else:
		aiming = false
		smooth_camera.fov = lerp(
			smooth_camera.fov,
			smooth_camera_fov,
			delta * 30
			)
		weapon_camera.fov = lerp(
			weapon_camera.fov,
			weapon_camera_fov,
			delta * 30
			)

func _physics_process(delta: float) -> void:
	handle_camera_rotation()
	# Add the gravity.
	if not is_on_floor():
		if velocity.y >= 0:
			velocity += get_gravity() * delta
		else:
			velocity += get_gravity() * delta * fall_multiplier

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * 2.0 * -get_gravity().y)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if aiming:
			velocity.z *= aim_multiplier
			velocity.x *= aim_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = -event.relative * 1/sensitivity
		if Input.is_action_pressed("aim"):
			mouse_motion *= aim_multiplier
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		

func handle_camera_rotation() -> void:
	rotate_y(mouse_motion.x)
	camera_pivot.rotate_x(mouse_motion.y)
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x, -90, 90
	)
	mouse_motion = Vector2.ZERO
