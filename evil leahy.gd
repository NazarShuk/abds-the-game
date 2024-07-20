extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var SPEED = 6.0
var speed = SPEED

var overwrite_speed = false

func _physics_process(_delta):
	if !overwrite_speed:
		speed = SPEED
	
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * speed
	
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




func _on_evil_leahy_area_entered(area):
	if area.name == "puddle":
		overwrite_speed = true
		speed = SPEED / 2
		$CPUParticles3D.show()
		await get_tree().create_timer(5).timeout
		overwrite_speed = false
		$CPUParticles3D.hide()
		
