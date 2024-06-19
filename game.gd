extends Node3D

var peer = SteamMultiplayerPeer.new()
var is_multiplayer = false

@onready var book_spawns = $BookSpawns
@onready var collected_books_label = $CanvasLayer/Main/CollectedBooksLabel

var players = {}
var players_ids = []

var lobby_id

@export var game_started = false

@export var canPlayersMove = true
@onready var evil_leahy = $EvilLeahy
var leahy_appeased = false

@export var leahy_speed : float

@export var min_left = 5
@export var sec_left = 1
 
@export var books_to_collect = 9
@export var total_books = 0
var book_pos = Vector3()

@export var leahy_look : bool

const FOX_OG_POS = Vector3(-19.722,1.24,-39.309)
@onready var mr_fox = $"Mr Fox"
var fox_follow = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	
	AudioVolume.load_values_and_apply()
	
	get_friends_lobbies()
	peer.lobby_created.connect(_on_lobby_connected)
	peer.lobby_joined.connect(_on_lobby_joined)
	
	print(Achievements.achievements )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_multiplayer && multiplayer.is_server():
		if game_started:
			collected_books_label.text = str(total_books) + " books collected out of " + str(books_to_collect)
		else:
			collected_books_label.text = "Find a ELA book!"
		leahy_speed = evil_leahy.SPEED
		$EvilLeahy/SubViewport/skibidiCamera.global_position = evil_leahy.global_position + Vector3(0,7,0)
		$EvilLeahy/SubViewport/skibidiCamera.global_rotation_degrees.x = -90
		$EvilLeahy/SubViewport/skibidiCamera.set_orthogonal(15,0.001,1000)
		
		var clr:Color = $CanvasLayer/Main/SomeoneDid.get("theme_override_colors/font_color")
		$CanvasLayer/Main/SomeoneDid.set("theme_override_colors/font_color",clr.lerp(Color(0,0,0,0),0.05))
		
		if fox_follow:
			mr_fox.update_target_location(book_pos)
		else:
			mr_fox.update_target_location(FOX_OG_POS)
		
	if game_started and !leahy_appeased and multiplayer.is_server() and !absent:
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
	
	
func _on_lobby_connected(_connected,id):
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id,"name",str(Steam.getPersonaName()) + "'s lobby")
		Steam.setLobbyJoinable(lobby_id,true)
		print(lobby_id)

func _on_lobby_joined():
	pass

func join_lobby(id):
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer/MultiPlayer/LoadingRect.show()

func _on_peer_connected(id = 1):
	
	var packed_player = load("res://player.tscn")
	var player = packed_player.instantiate()
	
	call_deferred("add_child",player)
	
	player.global_position = Vector3(randf_range(-12,12),5,randf_range(0,10))
	player.name = str(id)
	
	
	players[id] = {
		"id":id,
		"username":str(id),
		"books_collected":0,
		"is_dead":false,
		"deaths":0
	}
	players_ids.append(id)
	books_to_collect += 1
	

	
func _on_peer_disconnect(id):
	get_node(str(id)).queue_free()
	players.erase(players[id])
	
	players_ids.erase(id)
	
	print("cleaned peer")
	
	books_to_collect -= 1


func _on_connect_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost",7777)
	multiplayer.multiplayer_peer = peer

@rpc("any_peer","call_local")
func on_collect_book(id,book_name):
	print("on collect book called! by " + str(id))
	if multiplayer.is_server():
		var player_name = get_node(str(id)).steam_name
		if book_name != "Landmine":
			players[id].books_collected += 1
			var total = 0
		
			for idd in players_ids:
				total += players[idd].books_collected
			
			print("total: " + str(total))
			
			var spawnpoint = book_spawns.get_children().pick_random()
			spawnpoint = spawnpoint.global_position
			book_pos = spawnpoint
			spawn_book.rpc(spawnpoint,book_name)
			
			if total == 1:
				start_da_game.rpc()
				canPlayersMove = false
			elif total == books_to_collect:
				
				var total_deaths = 0
				for idd in players_ids:
					total_deaths += players[idd].deaths
				
				if total_deaths > 3:
					end_game.rpc("normal")
				elif total_deaths == 0:
					# impossible ending
					end_game.rpc("imp")
				elif total_deaths <= 3:
					# perfect run
					end_game.rpc("perfect")
			
			total_books = total
			
			evil_leahy.SPEED += 0.5
			
			info_text(player_name + " collected a book!")
			sec_left += 10
			fox_follow = false
		else:
			info_text(player_name + " exploded")
			var spawnpoint = $LandMineSpawns.get_children().pick_random()
			spawnpoint = spawnpoint.global_position
			spawnpoint.y = 0.143
			spawn_book.rpc(spawnpoint,book_name)
		
@rpc("authority","call_local")
func spawn_book(pos,old_book_name):
	get_node(str(old_book_name)).global_position = pos
	
	
@rpc("any_peer","call_local")
func use_vending_machine(id):
	if !multiplayer.is_server(): return
	if !game_started: return
	print("someone used a vending machine")
	
	for child in get_children():
		if child.name == str(id):
			child.choose_item.rpc_id(id)
			break

@rpc("authority","call_local")
func start_da_game():
	$bum.play()
	$Music1.stop()
	$Music2/Timer.start()
	$WelcomeLeahy.hide()
	$WelcomeLeahy/AudioStreamPlayer3D.stop()
	$CanvasLayer/Main/LeahyAngeredLabel.show()
	evil_leahy.show()
	evil_leahy.is_playing = true

	$grrrrrr.play()
	
	if multiplayer.is_server():
		Steam.setLobbyJoinable(lobby_id,false)
		leahy_look = true

func _on_host_local_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	
	_on_peer_connected()


func _on_timer_timeout():
	$Music2.play()

	$CanvasLayer/Main/LeahyAngeredLabel.hide()	
	$SecondsLeft.start()
	evil_leahy.play_audio()
	
	if multiplayer.is_server():
		canPlayersMove = true
		game_started = true
		leahy_look = false

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
				if game_played.lobby:
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
		if is_dead:
			players[id].deaths += 1
			info_text(get_node(str(id)).steam_name + " dissapeared")



func _on_seconds_left_timeout():
	#sec_left -= 1
	
	if min_left == 0 and sec_left == 0:
		$SecondsLeft.stop()
		end_game.rpc("worst")
	
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
func end_game(ending : String):
	if  multiplayer.is_server():
		players_ids.reverse()
		for id in players_ids:
			set_singleton.rpc_id(id,players[id].deaths,players[id].books_collected,ending)

@rpc("authority","call_local")
func set_singleton(deaths,books,ending):
	EndGameSingleton.deaths = deaths
	EndGameSingleton.books_collected = books
	
	peer.close()
	if ending == "normal":
		get_tree().change_scene_to_file("res://end.tscn")
	elif ending == "worst":
		get_tree().change_scene_to_file("res://bad_end.tscn")
	elif ending == "perfect":
		get_tree().change_scene_to_file("res://perfect_end.tscn")
	elif ending == "imp":
		get_tree().change_scene_to_file("res://impossible_end.tscn")

@rpc("authority","call_local")
func show_approaching_label():
	$CanvasLayer/Main/TextureRect.is_shown = true

@rpc("authority","call_local")
func hide_approaching_label():
	$CanvasLayer/Main/TextureRect.is_shown = false


func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://tutor.tscn")


func _on_button_3_pressed():
	get_tree().change_scene_to_file("res://settings.tscn")

func info_text(info):
	$CanvasLayer/Main/SomeoneDid.text = info
	$CanvasLayer/Main/SomeoneDid.set("theme_override_colors/font_color",Color.BLACK)

func hide_menu():
	$CanvasLayer/MultiPlayer.hide()
	$Music1.play()
	$Music0.stop()
	is_multiplayer = true


func _on_button_4_pressed():
	get_tree().change_scene_to_file("res://angy_azzu.tscn")

@rpc("any_peer","call_local")
func appease_leahy(username):
	if multiplayer.is_server():
		$Appeasment.start()
		leahy_appeased = true
		info_text(username + " appeased Leahy for 5 seconds.")


func _on_appeasment_timeout():
	leahy_appeased = false

@rpc("any_peer","call_local")
func mr_fox_collect():
	if multiplayer.is_server():
		fox_follow = true
		info_text("Follow Mr.Fox to find the notebook!")


func _on_button_5_pressed():
	get_tree().change_scene_to_file("res://achievements.tscn")

@rpc("any_peer","call_local")
func skibidi():
	peer.close()
	get_tree().change_scene_to_file("res://huh_ending.tscn")

@export var absent = false

func _on_absences_timeout():
	if !multiplayer.is_server() : return
	if !game_started : return
	
	# TODO: make sure its (0,15)
	if randi_range(0,15) == 1: 
		set_absent.rpc(true)
		absent = true
		hide_approaching_label.rpc()
	else:
		print("ms leahy still here")
		if absent == true:
			absent = false
			set_absent.rpc(false)

@rpc("authority","call_local")
func set_absent(is_absent : bool):
	
	var environment : Environment = $WorldEnvironment.environment
	
	if is_absent:
		evil_leahy.visible = false
		evil_leahy.is_playing = false
		environment.background_energy_multiplier = 0.1
		$Music2.pitch_scale = 0.5
	else:
		evil_leahy.visible = true
		evil_leahy.is_playing = true
		environment.background_energy_multiplier = 1
		$Music2.pitch_scale = 1

@rpc("authority","call_local")
func azzu_steal():
	if multiplayer.is_server():
		info_text("grr you angered azzu")
