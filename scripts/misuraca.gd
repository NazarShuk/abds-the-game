extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var unstucker = $Unstucker


var SPEED = 10

@export var server_target = false
@export var is_angry = false

var init_pos : Vector3

var angerer

const push_force = 1.0

var broken_machines = []

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
				angerer = Game.get_player_by_id(clorox.launcher)
				Game.info_text("Mr.Misuraca is angry")
	
	if multiplayer.is_server():
		unstucker.do_penalties = ((angerer != null) and broken_machines.size() > 0)
		
		go_back()
		fix_vending_machines()
		
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

func go_back():
	if angerer:
		update_target_location(angerer.global_position)
		is_angry = true
	else:
		update_target_location(init_pos)
		is_angry = false


func fix_vending_machines():
	if !multiplayer.is_server(): return
	var vending_machines = get_tree().get_nodes_in_group("vending_machines")
	
	broken_machines = []
	
	for machine in vending_machines:
		if machine.uses_left <= 0:
			broken_machines.append(machine)
			var dst = global_position.distance_to(machine.global_position)
			if dst < 2:
				machine.uses_left = machine.MAX_USES
	
	if !angerer and broken_machines.size() > 0:
		update_target_location(broken_machines[0].global_position)

func _on_misuraca_area_entered(area):
	if area.name == "PlayerArea":
		if angerer:
			if area.get_parent().name == angerer.name:
				angerer = null
