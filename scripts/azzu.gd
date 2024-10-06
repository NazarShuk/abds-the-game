extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var SPEED = 15

@export var server_target = false

const push_force = 1.0

func _physics_process(_delta):
	if !multiplayer.is_server(): return
	
	pick_up_expired_items()
	
	navigation()
	
	cloroxes()
	
	push_items()

func pick_up_expired_items():
	var expired_items = get_tree().get_nodes_in_group("expired_item")
	
	if expired_items.size() > 0:
		var closest_item = null
		var closetst_distance = INF
		
		for item in expired_items:
			var dst = global_position.distance_to(item.global_position) 
			if dst < closetst_distance:
				closetst_distance = dst
				closest_item = item
		
		update_target_location(closest_item.global_position)
		
		if global_position.distance_to(closest_item.global_position) < 1:
			closest_item.queue_free()

func navigation():
	if nav_agent.target_position:
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		
		var new_velocity = (next_location - current_location).normalized() * SPEED
		velocity = new_velocity
		look_at(next_location)
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		move_and_slide()

func cloroxes():
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		
		if distance < 5:
			if multiplayer.is_server():
				get_parent().azzu_steal.rpc(clorox.launcher)

func push_items():
	if multiplayer.is_server():
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			if collider is RigidBody3D:
				var push_direction = collision.get_normal()
				
				get_parent().push_item.rpc(collider.get_path(),push_direction,push_force)


func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location


func _on_timer_timeout():
	if !multiplayer.is_server(): return
	
	var points = get_parent().get_node("School/BookSpawns").get_children()
	
	update_target_location(points.pick_random().global_position)


