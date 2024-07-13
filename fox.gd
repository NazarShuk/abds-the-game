extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const INITIAL_SPEED = 7.5
var SPEED = 7.5

@export var mute : bool

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
		SPEED = INITIAL_SPEED - (get_parent().fox_notebooks_left * 0.5)

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location
