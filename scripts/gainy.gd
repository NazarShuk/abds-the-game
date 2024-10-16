extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var unstucker = $Unstucker

var SPEED = 20

var init_pos : Vector3

var current_player_target = null
@export var angered = false

func _ready():
	init_pos = global_position
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("ms_gainy"):
		queue_free()

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
	
	if multiplayer.is_server():
		angered = current_player_target != null
		unstucker.do_penalties = angered
		
		if current_player_target:
			
			if Game.players.has(current_player_target.name.to_int()):
				var player = Game.players[current_player_target.name.to_int()]
				if player.is_dead:
					current_player_target = null
			
			if current_player_target:
				update_target_location(current_player_target.global_position)
		else:
			go_back()
		

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location

func go_back():
	update_target_location(init_pos)


func _on_timer_timeout():
	if multiplayer.is_server():
		if Game.game_started:
			if randi_range(0,20) != 1: return
			
			attack_someone()

func attack_someone():
	if multiplayer.is_server():
		if Game.game_started:
			var just_a_chill_guy = get_tree().get_nodes_in_group("player").pick_random()
			
			if just_a_chill_guy:
				current_player_target = just_a_chill_guy
				Game.info_text("Ms.Gainy is angry at " + just_a_chill_guy.steam_name)


func _on_area_entered(area):
	if area.is_in_group("player_area"):
		if current_player_target:
			if area.get_parent().name == current_player_target.name:
				current_player_target = null
