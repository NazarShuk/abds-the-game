extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var unstucker = $Unstucker

const INITIAL_SPEED = 7.5
var SPEED = 7.5

@export var mute : bool

const push_force = 1.0

var initial_pos = Vector3.ZERO

func _ready():
	initial_pos = global_position

func _physics_process(_delta):
	if mute:
		$AudioStreamPlayer3D.volume_db = -80
	else:
		$AudioStreamPlayer3D.volume_db = 8.602
	
	if nav_agent.target_position:
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		
		var new_velocity = (next_location - current_location).normalized() * SPEED
		velocity = new_velocity
		move_and_slide()
	
	if multiplayer.is_server():
		SPEED = INITIAL_SPEED - (Game.fox_notebooks_left * 0.5)
		
		unstucker.do_penalties = Game.fox_notebooks_left > 0
		
		if Game.fox_notebooks_left > 0:
			var book = Game.get_closest_node_in_group(global_position,"Book")
			
			if book:
				update_target_location(book.global_position)
			else:
				update_target_location(initial_pos)
		
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			# If the collider is a RigidBody
			if collider is RigidBody3D:
				# Calculate the push direction
				var push_direction = collision.get_normal()
				
				# Apply the force to the RigidBody
				collider.push_item.rpc(push_direction,push_force)

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location
