extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var SPEED = 15

@export var server_target = false

const push_force = 1.0

func _physics_process(_delta):
	if nav_agent.target_position:
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		
		var new_velocity = (next_location - current_location).normalized() * SPEED
		velocity = new_velocity
		look_at(next_location)
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		move_and_slide()
		
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		
		if distance < 5:
			if multiplayer.is_server():
				get_parent().azzu_steal.rpc(clorox.launcher)
	
	if multiplayer.is_server():
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			# If the collider is a RigidBody
			if collider is RigidBody3D:
				# Calculate the push direction
				var push_direction = collision.get_normal()
				
				# Apply the force to the RigidBody
				get_parent().push_item.rpc(collider.get_path(),push_direction,push_force)
				#collider.apply_central_impulse(-push_direction * push_force)
	
	

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location


func _on_timer_timeout():
	#if server_target: return
	if !multiplayer.is_server(): return
	var points = get_parent().get_node("School/BookSpawns").get_children()
	
	update_target_location(points.pick_random().global_position)


