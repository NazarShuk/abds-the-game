extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var SPEED = 20

@export var server_target = false

var init_pos : Vector3

func _ready():
	init_pos = global_position

func _physics_process(_delta):
	if nav_agent.target_position:
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		
		var new_velocity = (next_location - current_location).normalized() * SPEED
		velocity = new_velocity
		if global_position.distance_to(next_location) > 1.5:
			look_at(next_location)
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		move_and_slide()
		

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location

func go_back():
	update_target_location(init_pos)
