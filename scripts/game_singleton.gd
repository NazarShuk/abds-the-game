extends Node

var game_started = false
signal on_game_started
var pre_game_started = false
signal on_pre_game_started

var powered_off = false

signal on_power_changed(power_on)

var world_environment : WorldEnvironment
var environment
var sun

signal on_info_text(text : String)

var books_to_collect = 9
var collected_books = 0
var book_boost = 0

signal on_book_collected(amount)

var game_params := GameParams.new()
signal on_customization_reset

# server only
var players = {}


func reset_values():
	game_started =         false
	pre_game_started =     false
	powered_off =          false
	players =              {}
	world_environment =    null
	environment =          null
	sun =                  null
	books_to_collect =     9
	collected_books =      0
	book_boost =           0
	game_params =  GameParams.new()

func _ready():
	on_game_started.connect(_on_game_started)
	on_pre_game_started.connect(_on_pre_game_started)

@rpc("authority","call_local")
func set_customization(key, value):
	game_params.set_param(key,value)

@rpc("authority","call_local")
func clear_customization():
	game_params = GameParams.new()
	on_customization_reset.emit()

@rpc("authority","call_local")
func set_book_boost(val : float):
	book_boost = val

@rpc("authority","call_local")
func add_book_boost(val : float):
	book_boost += val

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
	pre_game_started = true
	on_pre_game_started.emit()

@rpc("authority","call_local")
func add_collected_books(amount : float):
	var did_collect = collected_books < (collected_books + amount)
	collected_books += amount
	
	if did_collect:
		on_book_collected.emit(amount)


@rpc("authority","call_local")
func set_collected_books(amount : float):
	var difference = amount - collected_books
	var did_collect = collected_books < amount
	collected_books = amount
	
	if did_collect:
		on_book_collected.emit(difference)

func calculate_total_books():
	if !multiplayer.is_server(): return
	var total = 0
	for player_id in Game.players.keys():
		total += Game.players[player_id].books_collected
	
	Game.set_collected_books.rpc(total)


@rpc("authority","call_local")
func set_books_to_collect(amount : float):
	books_to_collect = amount

@rpc("any_peer","call_local")
func set_powered_off(val : bool):
	powered_off = val
	on_power_changed.emit(!val)

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
	var pls = get_tree().get_nodes_in_group("player")
	
	for player in pls:
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



