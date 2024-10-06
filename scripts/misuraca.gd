extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


var SPEED = 10

@export var server_target = false
@export var is_angry = false

var init_pos : Vector3

var angerer

const push_force = 1.0

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
	

	
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		
		if distance < 5:
			if multiplayer.is_server():
				angerer = get_parent().get_node(NodePath(str(clorox.launcher)))
				Game.info_text.rpc("Mr.Misuraca is angry")
	
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

func go_back():
	if angerer:
		
		update_target_location(angerer.global_position)
		is_angry = true
	else:
		update_target_location(init_pos)
		is_angry = false
