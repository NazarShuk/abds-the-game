extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var SPEED = 6.0

func _physics_process(_delta):
	
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * SPEED
	
	velocity = new_velocity
	if global_transform.origin != next_location:
		if global_position.distance_to(next_location) > 1.5:
			look_at(next_location)
		rotation_degrees.x = 0
		rotation_degrees.z = 0
	
	if multiplayer.is_server():
		var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
		for clorox in cloroxes:
			if global_position.distance_to(clorox.global_position) < 1:
				velocity = Vector3()
		
	move_and_slide()
	

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location


