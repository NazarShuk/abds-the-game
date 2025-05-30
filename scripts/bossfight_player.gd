extends CharacterBody3D
class_name BossfightPlayer

const CLOROX = preload("uid://c2vmxxh2ektax")

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

var cloroxes_left = 3

func _ready():
	# Capture mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	cloroxes()

func cloroxes():
	if cloroxes_left >= 3:
		$CanvasLayer/item3.show()
	else:
		$CanvasLayer/item3.hide()
	
	if cloroxes_left >= 2:
		$CanvasLayer/item2.show()
	else:
		$CanvasLayer/item2.hide()
		
	if cloroxes_left >= 1:
		$CanvasLayer/item.show()
	else:
		$CanvasLayer/item.hide()
	
	if Input.is_action_just_pressed("use_item"):
		if cloroxes_left > 0:
			cloroxes_left -= 1
			$Head/Hands/AnimationPlayer.play("clorox_use")
			await get_tree().create_timer(0.4, false).timeout
			var clorox = CLOROX.instantiate()
			add_sibling(clorox)
			clorox.global_position = camera.global_position
			clorox.global_rotation = camera.global_rotation
			
			await $Head/Hands/AnimationPlayer.animation_finished
			if cloroxes_left > 0:
				$Head/Hands/AnimationPlayer.play("clorox_open")
	
	if Input.is_action_pressed("jump"):
		head.rotation_degrees.y = 180
	else:
		head.rotation_degrees.y = 0

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
	if velocity.length() <= 0.1 or not is_on_floor():
		wobble_time = 0
	
	camera_wobble.x = lerp(camera_wobble.x, sin(wobble_time) * 0.1, delta * 20)
	camera_wobble.y = lerp(camera_wobble.y, abs(cos(wobble_time)) * 0.1, delta * 20)
