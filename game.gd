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
 
@export var books_to_collect = 6
@export var total_books = 0
var book_pos = Vector3()

@export var leahy_look : bool

@onready var FOX_OG_POS = $"Mr Fox".global_position
@onready var mr_fox = $"Mr Fox"
var fox_follow = false

@export var is_pacer = false
@export var pacer_deadly = false

var debug_host = false

var leahy_diff = 9999
var leahy_last_pos = Vector3(0,0,0)
var leahy_diff_penalty = 0

@onready var mr_azzu = $Mr_Azzu
@export var azzu_angered = false

# Customization
@export var do_azzu_steal = true # DONE
@export var do_fox_help = true # DONE
@export var do_leahy_appease = true # DONE
@export var do_absences = true # DONE
@export var do_silent_lunch = true # DONE
@export var landmine_death = false # DONE
@export var do_vertical_camera = false # DONE

@export var notebooks_per_player = 1 # DONE
@export var max_deaths = 10 # DONE
@export var leahy_start_speed = 6.0 # DONE
@export var leahy_speed_per_notebook = 0.5 # DONE
@export var absence_chance = 15 # DONE
@export var absence_interval = 15 # DONE
@export var death_timeout = 5 # DONE
@export var silent_lunch_duration = 15 # DONE



# Called when the node enters the scene tree for the first time.
func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	
	AudioVolume.load_values_and_apply()
	
	get_friends_lobbies()
	peer.lobby_created.connect(_on_lobby_connected)
	peer.lobby_joined.connect(_on_lobby_joined)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


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
		
		#var clr:Color = $CanvasLayer/Main/SomeoneDid.get("theme_override_colors/font_color")
		#$CanvasLayer/Main/SomeoneDid.set("theme_override_colors/font_color",clr.lerp(Color(0,0,0,0),0.05))
		
		if fox_follow && do_fox_help:
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



func _input(event):
	if event.is_action_type():
		if event.is_action_pressed("fullscreen"):
			if Allsingleton.is_fullscreen == false:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			
			Allsingleton.is_fullscreen = !Allsingleton.is_fullscreen

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

func _on_lobby_joined():
	pass

func join_lobby(id):
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer/MultiPlayer/LoadingRect.show()

func _on_connected_to_server():
	pass

func _on_peer_connected(id = 1):
	print("_on_peer_connected")
	#$CanvasLayer/MultiPlayer/LoadingRect.show()
	
	
	var packed_player = preload("res://player.tscn")
	var player = packed_player.instantiate()
	
	player.set_multiplayer_authority(id)
	player.name = str(id)
	
	
	#call_deferred("add_child",player)
	#add_player.rpc(id)
	#for pl_id in players_ids:
	#	add_player.rpc_id(id,pl_id)
	
	
	players[id] = {
		"id":id,
		"username":str(id),
		"books_collected":0,
		"is_dead":false,
		"deaths":0
	}
	players_ids.append(id)
	books_to_collect += notebooks_per_player




	
func _on_peer_disconnect(id):
	get_node(str(id)).queue_free()
	players.erase(players[id])
	
	players_ids.erase(id)
	
	books_to_collect -= 1


func _on_connect_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost",7777)
	multiplayer.multiplayer_peer = peer

@rpc("any_peer","call_local")
func on_collect_book(id,book_name):
	if multiplayer.is_server():
		var player_name = get_node(str(id)).steam_name
		if book_name != "Landmine":
			players[id].books_collected += 1
			var total = 0
		
			for idd in players_ids:
				total += players[idd].books_collected
			
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
			
			evil_leahy.SPEED += leahy_speed_per_notebook
			
			info_text(player_name + " collected a book!")
			sec_left += 10
			fox_follow = false
		else:
			
			
			info_text(player_name + " slipped")
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
		if !debug_host:
			Steam.setLobbyJoinable(lobby_id,false)
		leahy_look = true

func _on_host_local_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	
	debug_host = true
	
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
		$FakeFox/AnimationPlayer.play("new_animation")
		evil_leahy.SPEED = leahy_start_speed
		$Absences.start(absence_interval)

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
		
		if !game_played.is_empty():
			if game_played.id == OS.get_environment("SteamAppID").to_int():
				if game_played.lobby:
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
			var total_deaths = 0
			for pl_id in players_ids:
				total_deaths += players[pl_id].deaths
			
			info_text(get_node(str(id)).steam_name + " dissapeared. " + str(total_deaths) + "/10")
			if is_pacer:
				stop_pacer.rpc()
			
			
			if total_deaths >= max_deaths:
				end_game.rpc("worst")



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
	#$CanvasLayer/Main/SomeoneDid.text = info
	#$CanvasLayer/Main/SomeoneDid.set("theme_override_colors/font_color",Color.BLACK)
	get_node("1").info_text.rpc(info)

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
		if !do_leahy_appease: return
		
		$Appeasment.start()
		leahy_appeased = true
		info_text(username + " appeased Leahy for 5 seconds.")


func _on_appeasment_timeout():
	leahy_appeased = false

@rpc("any_peer","call_local")
func mr_fox_collect():
	if multiplayer.is_server():
		if do_fox_help:
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
	if !do_absences: return
	
	if randi_range(0,absence_chance) == 1: 
		set_absent.rpc(true)
		absent = true
		hide_approaching_label.rpc()
	else:
		if absent == true:
			absent = false
			set_absent.rpc(false)
	
	$Absences.start(absence_interval)

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

@rpc("any_peer","call_local")
func azzu_steal(launcher):
	
	if multiplayer.is_server() && canPlayersMove:
		if !do_azzu_steal: return
		
		info_text("grr you angered azzu")
		canPlayersMove = false
		mr_azzu.server_target = true
		mr_azzu.update_target_location(get_node(str(launcher)).global_position)
		
		azzu_angered = true
	
	if canPlayersMove: return
	
	$Music2.stop()

@rpc("any_peer","call_local")
func azzu_dont_steal():
	if multiplayer.is_server():
		canPlayersMove = true
		azzu_angered = false
		mr_azzu.server_target = false
		mr_azzu._on_timer_timeout()
		
	
	$Music2.play()
	
@rpc("any_peer","call_local")
func start_da_pacer(id):
	
	# For everyone
	$FakeFox/PacerTest.play()
	$Music2.stop()
	$FakeFox.show()
	$"Mr Fox".hide()
	$"Mr Fox".mute = true
	
	# Server only
	if multiplayer.is_server():
		for pl in players_ids:
			get_node(str(pl)).server_pos.rpc_id(pl,$PacerPos.global_position)
		
		var username = get_node(str(id)).steam_name
		info_text(username + " angered Mr.Fox...")
		leahy_appeased = true
		$FakeFox/PacerTest/PacerStartTimer.start()
		canPlayersMove = false


func _on_pacer_start_timer_timeout():
	leahy_appeased = false
	canPlayersMove = true
	is_pacer = true
	info_text("FOLLOW MR.FOX OR ELSE...")
	$FakeFox/PacerTest/PacerStartTimer2.start()
	
func _on_pacer_start_timer_2_timeout():
	pacer_deadly = true
	$FakeFox/PacerTest/PacerSpeedIncrease.start()

@rpc("authority","call_local")
func stop_pacer():
	$FakeFox/PacerTest.stop()
	$Music2.play()
	$FakeFox.hide()
	$FakeFox/PacerTest/PacerSpeedIncrease.stop()
	$FakeFox/AnimationPlayer.speed_scale = 1
	$"Mr Fox".show()
	$"Mr Fox".mute = false
	
	if multiplayer.is_server():
		is_pacer = false
		pacer_deadly = false


func _on_pacer_speed_increase_timeout():
	$FakeFox/AnimationPlayer.speed_scale += 0.005


func _on_leahy_pos_diff_timeout():
	if !multiplayer.is_server(): return
	
	leahy_diff = evil_leahy.global_position.distance_to(leahy_last_pos)
	leahy_last_pos = evil_leahy.global_position
	if leahy_diff < 1 and !leahy_appeased and !absent and game_started:
		leahy_diff_penalty += 1
	if leahy_diff > 1 and !leahy_appeased and !absent and game_started:
		leahy_diff_penalty = 0
	
	if leahy_diff_penalty > 7:
		var min_dst = 99999
		var cls_pos = Vector3(0,0,0)
		for respawn_pos : Node3D in $LeahyPenaltyPos.get_children():
			var dst = evil_leahy.global_position.distance_to(respawn_pos.global_position)
			if dst < min_dst:
				cls_pos = respawn_pos.global_position
				min_dst = dst
		
		evil_leahy.global_position = cls_pos
		leahy_diff_penalty = 0


func _on_open_config_pressed():
	$CanvasLayer/MultiPlayer/ConfigPanel.visible = !$CanvasLayer/MultiPlayer/ConfigPanel.visible


func _on_reset_to_default_pressed():
	var checkboxes = get_tree().get_nodes_in_group("checkbox")
	
	for checkbox in checkboxes:
		checkbox.go_to_inital()


func _on_button_6_pressed():
	get_tree().quit()
