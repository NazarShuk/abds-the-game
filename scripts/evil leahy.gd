extends CharacterBody3D

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var unstucker = $Unstucker

var SPEED = 6.0
var speed = SPEED

var overwrite_speed = false

const push_force = 1.0

var distance_to_target = -1

func _physics_process(_delta):
	if !overwrite_speed:
		speed = SPEED
	
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * speed
	
	distance_to_target = 0
	
	var path = nav_agent.get_current_navigation_path()
	
	for point in range(path.size()):
		if path[point - 1]:
			distance_to_target += path[point - 1].distance_to(path[point])
		else:
			distance_to_target += global_position.distance_to(path[point])
	
	distance_to_target = distance_to_target / 2
	
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
		
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			# If the collider is a RigidBody
			if collider is RigidBody3D:
				# Calculate the push direction
				var push_direction = collision.get_normal()
				
				# Apply the force to the RigidBody
				collider.push_item.rpc(push_direction,push_force)
		
	move_and_slide()

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location

func _on_evil_leahy_area_entered(area):
	if area.name == "puddle":
		if !area.get_parent().can_slowdown: return
		
		overwrite_speed = true
		speed = SPEED / 2
		$CPUParticles3D.show()
		await Game.sleep(5)
		overwrite_speed = false
		$CPUParticles3D.hide()


func _on_pitch_timer_timeout():
	$AudioStreamPlayer3D.pitch_scale = randf_range(0.5,1.5)
