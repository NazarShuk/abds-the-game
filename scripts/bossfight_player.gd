extends CharacterBody3D
class_name BossfightPlayer

const CLOROX_BOSSFIGHT_EDITION = preload("res://scenes/clorox_bossifight_edition.tscn")

# Player movement parameters
@export var SPEED = 6.0
@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.003

# Camera rotation limits (in radians)
const MAX_CAMERA_ROTATION = 1.5  # About 85 degrees

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@export var camera : Camera3D

var target_fov = 75

@export var target_player_pos : Node3D

var has_clorox = false

var push_force = Vector3.ZERO

func _ready():
	# Capture mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	# Handle mouse movement
	if event is InputEventMouseMotion:
		# Rotate the head (up/down)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Clamp the vertical rotation
		head.rotation.x = clamp(head.rotation.x, -MAX_CAMERA_ROTATION, MAX_CAMERA_ROTATION)
		# Rotate the body (left/right)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# Handle escape key to free mouse
	if event.is_action_pressed("escape"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	
	if target_player_pos and target_player_pos.do_target:
		global_position = target_player_pos.global_position
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var running = Input.is_action_pressed("sprint")
	
	# Handle movement
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if running:
			velocity.x *= 2
			velocity.z *= 2
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if running:
		target_fov = 90
	else:
		target_fov = 75
	
	camera.fov = lerp(camera.fov, float(target_fov), delta * 2.5)
	
	velocity += push_force
	push_force = push_force.lerp(Vector3.ZERO, delta * 100)
	
	move_and_slide()
	
	$Head/clorox.visible = has_clorox
	
	if Input.is_action_just_pressed("use_item") and has_clorox:
		var clorox = CLOROX_BOSSFIGHT_EDITION.instantiate()
		get_parent().add_child(clorox)
		clorox.global_position = global_position
		clorox.global_rotation = global_rotation
		has_clorox = false
	
	if get_parent().is_in_group("bossfight2"):
		if global_position.y < -30:
			get_parent().respawn()


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.name == "darel":
		get_tree().reload_current_scene()
	
	if get_parent().is_in_group("bossfight2"):
		if area.is_in_group("clorox_bossfight"):
			get_parent().respawn()
		
		if area.is_in_group("leahyboss"):
			# Calculate push direction from leahyboss to the player (self)
			var push_direction = global_position - area.global_position
			
			# Normalize the direction and add upward force
			push_direction = -push_direction.normalized()
			
			# Apply the force to self (the player)
			var push_strength = 10.0  # Adjust this value for stronger/weaker push
			push_force += push_direction * push_strength
