extends Node3D

var peer = SteamMultiplayerPeer.new()
@onready var book_spawns = $BookSpawns
@onready var collected_books_label = $CanvasLayer/Main/CollectedBooksLabel

var players = {}
var players_ids = []

var lobby_id

@export var game_started = false

@export var canPlayersMove = true
@onready var evil_leahy = $EvilLeahy

var min_left = 5
var sec_left = 1



# Called when the node enters the scene tree for the first time.
func _ready():
	peer.lobby_created.connect(_on_lobby_connected)
	get_friends_lobbies()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_started and multiplayer.is_server():
		var closest
		var closest_distance = 999999999
		
		for p in players_ids:
			if !players[p].is_dead:
				var distance = evil_leahy.global_position.distance_to(get_node(str(p)).global_position)
			
				update_approching_label.rpc_id(p,distance)
			
				if distance < closest_distance:
					closest = get_node(str(p)).global_position
					closest_distance = distance
					show_approaching_label.rpc_id(p)
				else:
					hide_approaching_label.rpc_id(p)
			else:
				hide_approaching_label.rpc_id(p)
		
		if closest:
			get_tree().call_group("enemies","update_target_location",closest)

	

func _on_host_pressed():
	peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_FRIENDS_ONLY)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	_on_peer_connected()
	$CanvasLayer/MultiPlayer.hide()
	$Music1.play()
	
	
func _on_lobby_connected(connected,id):
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id,"name",str(Steam.getPersonaName()) + "'s lobby")
		Steam.setLobbyJoinable(lobby_id,true)
		print(lobby_id)
		
func join_lobby(id):
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer/MultiPlayer.hide()	
	$Music1.play()

func _on_peer_connected(id = 1):
	
	var packed_player = load("res://player.tscn")
	var player = packed_player.instantiate()
	
	player.name = str(id)
	
	call_deferred("add_child",player)
	
	players[id] = {
		"id":id,
		"books_collected":0,
		"is_dead":false
	}
	players_ids.append(id)

	
func _on_peer_disconnect(id):
	get_node(str(id)).queue_free()
	players.erase(players[id])
	
	players_ids.erase(id)
	
	print("cleaned peer")



func _on_connect_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost",7777)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer/MultiPlayer.hide()
	$Music1.play()
	

@rpc("any_peer","call_local")
func on_collect_book(id,book_name):
	print("on collect book called! by " + str(id))
	if multiplayer.is_server():
		players[id].books_collected += 1
		var total = 0
	
		for idd in players_ids:
			total += players[idd].books_collected
		
		print("total: " + str(total))
		
		var spawnpoint = book_spawns.get_children().pick_random()
		spawnpoint = spawnpoint.global_position
	
		update_book_text.rpc(total,spawnpoint,book_name)
		
		if total == 1:
			start_da_game.rpc()
			canPlayersMove = false
		elif total == 10:
			end_game.rpc(true)
		
		evil_leahy.SPEED += 1.0
		
@rpc("authority","call_local")
func update_book_text(total,pos,old_book_name):
	collected_books_label.text = str(total) + " books collected out of 10"
	
	for book in get_tree().get_nodes_in_group(old_book_name):
		book.queue_free()
	
	var packed_book = load("res://book.tscn")
	var book = packed_book.instantiate()
	book.global_position = pos
	book.name = "book_" + str(randi_range(1111,9999))
	book.add_to_group("book_" + str(randi_range(1111,9999)))
	add_child(book,true)
	
@rpc("any_peer","call_local")
func use_vending_machine():
	print("someone used a vending machine")

@rpc("authority","call_local")
func start_da_game():
	$bum.play()
	$Music1.stop()
	$Music2/Timer.start()
	$WelcomeLeahy.hide()
	$WelcomeLeahy/AudioStreamPlayer3D.stop()
	$CanvasLayer/Main/LeahyAngeredLabel.show()
	evil_leahy.show()
	evil_leahy.play_audio()
	$Doors/DoorBlocker/CollisionShape3D.disabled = false

func _on_host_local_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	
	_on_peer_connected()
	$CanvasLayer/MultiPlayer.hide()
	$Music1.play()


func _on_timer_timeout():
	$Music2.play()

	$CanvasLayer/Main/LeahyAngeredLabel.hide()	
	$SecondsLeft.start()
	$CanvasLayer/Main/TimerLabel.show()
	
	if multiplayer.is_server():
		canPlayersMove = true
		game_started = true

@rpc("authority","call_local")
func update_approching_label(meters):
	$CanvasLayer/Main/TextureRect/Label.text = str(round(meters))

func get_friends_lobbies():
	
	for child in $CanvasLayer/MultiPlayer/ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	
	var friend_count = Steam.getFriendCount()
	
	var total_playing = 0
	
	for i in range(0,friend_count):
		var friend = Steam.getFriendByIndex(i,Steam.FRIEND_FLAG_ALL)
		var friend_name = Steam.getFriendPersonaName(friend)
		
		var game_played = Steam.getFriendGamePlayed(friend)
		#print(friend_name)
		
		if !game_played.is_empty():
			if game_played.id == OS.get_environment("SteamAppID").to_int():
				#print(friend_name + " is playing spacewar!")
				var btn = Button.new()
				btn.text = "Join " + friend_name
				btn.connect("pressed",Callable(self,"join_lobby").bind(game_played.lobby))
				
				$CanvasLayer/MultiPlayer/ScrollContainer/VBoxContainer.add_child(btn)
				total_playing += 1
				
	if total_playing == 0:
		var label : Label = Label.new()
		label.text = "no friends are playing :("
		
		$CanvasLayer/MultiPlayer/ScrollContainer/VBoxContainer.add_child(label)


func _on_button_pressed():
	get_friends_lobbies()

@rpc("any_peer","call_local")
func set_played_dead(id,is_dead):
	if multiplayer.is_server():
		players[id].is_dead = is_dead



func _on_seconds_left_timeout():
	sec_left -= 1
	
	if min_left == 0 and sec_left == 0:
		$SecondsLeft.stop()
		end_game.rpc(false)
	
	if sec_left <= 0:
		min_left -= 1
		
		sec_left = 59
	
	var min_str = str(min_left)
	
	if min_left < 10:
		min_str = "0" + str(min_left)
	
	var sec_str = str(sec_left)
	
	if sec_left < 10:
		sec_str = "0" + str(sec_left)
	
	$CanvasLayer/Main/TimerLabel.text = min_str + ":" + sec_str
	
	

@rpc("authority","call_local")
func end_game(won : bool):
	peer.close()
	if won:
		get_tree().change_scene_to_file("res://end.tscn")
	else:
		get_tree().change_scene_to_file("res://bad_end.tscn")

@rpc("authority","call_local")
func show_approaching_label():
	$CanvasLayer/Main/TextureRect.is_shown = true

@rpc("authority","call_local")
func hide_approaching_label():
	$CanvasLayer/Main/TextureRect.is_shown = false
