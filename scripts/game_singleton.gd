extends Node

var game_started = false
signal on_game_started
var pre_game_started = false
signal on_pre_game_started

var powered_off = false

var world_environment : WorldEnvironment
var environment
var sun

signal on_info_text(text : String)

# server only
var fox_notebooks_left = 0

func reset_values():
	game_started = false
	pre_game_started = false
	powered_off = false
	fox_notebooks_left = 0

func _ready():
	on_game_started.connect(_on_game_started)
	on_pre_game_started.connect(_on_pre_game_started)

func _on_game_started():
	print_rich("[color=orange]GAME STARTED[/color]")
	game_started = true

func _on_pre_game_started():
	print_rich("[color=orange]PRE GAME STARTED[/color]")
	pre_game_started = true

@rpc("authority","call_local")
func set_game_started():
	game_started = true
	on_game_started.emit()

@rpc("authority","call_local")
func set_pre_game_started():
	pre_game_started
	on_pre_game_started.emit()

@rpc("any_peer","call_local")
func set_param(param_name : String, val):
	set(param_name,val)

func info_text(text : String):
	rpc_info_text(text)

@rpc("any_peer","call_local")
func rpc_info_text(text):
	on_info_text.emit(text)

# wait for seconds
func sleep(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.start(seconds)
	
	await timer.timeout
	timer.queue_free()

func get_player_by_id(id : int):
	var players = get_tree().get_nodes_in_group("player")
	
	for player in players:
		if player.name == str(id):
			return player

func get_closest_node_in_group(position : Vector3, group : String):
	var nodes = get_tree().get_nodes_in_group(group)
	
	var closest_node = null
	var closest_dst = INF
	
	for node in nodes:
		var dst = position.distance_to(node.global_position)
		
		if dst < closest_dst:
			closest_dst = dst
			closest_node = node
	
	return closest_node
	
	

