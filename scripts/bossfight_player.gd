extends CharacterBody3D
class_name BossfightPlayer

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


var camera_wobble = Vector2.ZERO
var wobble_time = 0

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
	camera.h_offset = camera_wobble.x
	camera.v_offset = camera_wobble.y
	
	move_and_slide()
	
	camera_wobble_function(delta)


func camera_wobble_function(delta : float):
	wobble_time += delta * velocity.length()
	
	camera_wobble.x = lerp(camera_wobble.x, sin(wobble_time) * 0.25, delta * 20)
	camera_wobble.y = lerp(camera_wobble.y, abs(cos(wobble_time)) * 0.25, delta * 20)
