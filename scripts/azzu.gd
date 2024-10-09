extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var SPEED = 15

const push_force = 1.0

var current_player_target = null
@export var angered = false

func _ready():
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("mr_azzu"):
		queue_free()

func _physics_process(_delta):
	if !multiplayer.is_server(): return
	
	anger_issues()
	
	pick_up_expired_items()
	
	navigation()
	
	cloroxes_anger()
	
	push_items()

func anger_issues():
	angered = current_player_target != null
	
	if current_player_target:
		update_target_location(current_player_target.global_position)

func pick_up_expired_items():
	if current_player_target: return
	
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

func cloroxes_anger():
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		
		if distance < 5:
			if multiplayer.is_server():
				var player = Game.get_player_by_id(clorox.launcher)
				if !player: return
				
				current_player_target = player
				Game.info_text("Mr.Azzu is angry")
			
			break

func push_items():
	if multiplayer.is_server():
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			if collider is RigidBody3D:
				var push_direction = collision.get_normal()
				collider.push_item.rpc(push_direction,push_force)


func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location


func _on_timer_timeout():
	if !multiplayer.is_server(): return
	
	var points = get_tree().get_nodes_in_group("book_spawn")
	update_target_location(points.pick_random().global_position)

func _on_azzu_area_entered(area):
	if area.is_in_group("player_area"):
		if current_player_target:
			if area.get_parent().name == current_player_target.name:
				current_player_target = null
