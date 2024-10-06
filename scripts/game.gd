extends Node3D

var peer = SteamMultiplayerPeer.new()

@onready var book_spawns = $School/BookSpawns
@onready var collected_books_label = $CanvasLayer/Main/CollectedBooksLabel

var players = {}
var players_ids = []
@export var players_in_lobby = 0

var lobby_id

@export var canPlayersMove = true
@onready var evil_leahy = $EvilLeahy
@export var leahy_appeased = false

@export var leahy_speed : float
 
@export var books_to_collect = 9
@export var total_books = 0
var book_pos = Vector3()
var book_boost = 0

@export var leahy_look : bool

@onready var FOX_OG_POS = $"Mr Fox".global_position
@onready var mr_fox = $"Mr Fox"
var fox_follow = false

@export var is_pacer = false
@export var pacer_deadly = false
var is_pacer_intro = false

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
@export var do_gainy_spawn = true # DONE
@export var do_absences = true # DONE
@export var do_silent_lunch = true # DONE
@export var landmine_death = false # DONE
@export var do_vertical_camera = false # DONE
@export var enable_breaker = true  # DONE
@export var enable_shop = true # DONE
@export var enable_coffee = true # DONE

@export var notebooks_per_player = 1 # DONE
@export var max_deaths = 9 # DONE
@export var deaths_per_player = 1 # DONE
@export var leahy_start_speed = 6.0 # DONE
@export var leahy_speed_per_notebook = 0.5 # DONE
@export var absence_chance = 15 # DONE
@export var absence_interval = 15 # DONE
@export var gainy_attack_chance = 20 # DONE
@export var gainy_attack_interval = 30
@export var death_timeout = 5 # DONE
@export var silent_lunch_duration = 15 # DONE
@export var shop_timeout = 60 # DONE
@export var breaker_timeout = 60 # DONE
@export var coffee_timeout = 20  # DONE

@export var do_achievements = true


@export var shop : StaticBody3D

@onready var player_list_text = $CanvasLayer/Lobby/playerListText
var players_spawned = false

var pacer_times = []

@export var is_in_lobby = false

@export var school : Node3D

var enable_live_split = true

@export var controls_text : Label

var do_vertical_camera_normal = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Game.world_environment = $"Lighting and stuff/WorldEnvironment"
	Game.environment = Game.world_environment.environment
	Game.sun = $"Lighting and stuff/DirectionalLight3D"
	
	
	AudioServer.set_bus_solo(6,false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	
	Settings.load_values_and_apply()
	if Settings.render_distance:
		$pre_start_game_anim/Camera3D.far = Settings.render_distance
	
	get_friends_lobbies()
	peer.lobby_created.connect(_on_lobby_connected)
	peer.lobby_joined.connect(_on_lobby_joined)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_disconnect_from_server)
	peer.lobby_kicked.connect(_on_disconnect_from_server)
	
	if Settings.better_lighting != null:
		Game.sun.visible = Settings.better_lighting
	
	
	if Allsingleton.is_bossfight:
		$CanvasLayer/Glitch.show()
		$WelcomeLeahy.hide()
		$WelcomeLeahy/AudioStreamPlayer3D.stop()
		$Music1.stream = load("res://pre_boss.mp3")
		$Music2.stream = load("res://dariel/placeholders/Glory [kzbbO_lyZ94].mp3")
		$Music0.stream = load("res://noise.mp3")
		$Music0.play()
		
		# Main menu
		$CanvasLayer/MultiPlayer/Title.hide()
		$CanvasLayer/MultiPlayer/ItemList.hide()
		$"CanvasLayer/MultiPlayer/refresh btn".hide()
		$CanvasLayer/MultiPlayer/azzu.hide()
		
		# Lobby
		$CanvasLayer/Lobby/Button7.hide()
		$CanvasLayer/Lobby/Button8.hide()
		$CanvasLayer/Lobby/Label4.hide()
		$CanvasLayer/Lobby/Label2.hide()
		$CanvasLayer/Lobby/achievement.hide()
		$CanvasLayer/Lobby/Label3.hide()
		$CanvasLayer/Lobby/playerListText.hide()
		
		Game.sun.visible = false

var leahy_power_fix_num = 0
var music_pitch_target = 1
var music_pitch_boost = 1



@export var is_leahy_baja_blast = false
var leahy_baja_timer = 0

var is_misuraca_fixing = false
var is_misuraca_disabled = false

@onready var boss_bar = $CanvasLayer/Main/Bossbar/ProgressBar
@onready var evil_darel = $EvilDarel
@onready var previous_darel_health = evil_darel.health

var leahy_p_timeout = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if Input.is_anything_pressed():
		$CanvasLayer/handelr.hide()
	
	if multiplayer.has_multiplayer_peer() && multiplayer.is_server():
		if Allsingleton.is_bossfight:
			
			if Input.is_action_just_pressed("debug"):
				evil_darel.health -= 5
			
			if Game.game_started:
				boss_bar.value = lerp(boss_bar.value,float(evil_darel.health),0.1)
				evil_darel.look_at(get_tree().get_first_node_in_group("player").global_position)
				
				$CanvasLayer/Main.scale = lerp($CanvasLayer/Main.scale, Vector2(1,1),0.1)
				
				if previous_darel_health > evil_darel.health:
					$CanvasLayer/Main.scale += Vector2(0.1,0.1)
				
				previous_darel_health = evil_darel.health
				music_pitch_target = 1 #((100 - evil_darel.health) / 200) + 1
				
				if !evil_darel.is_phase_2:
					if evil_darel.health < 50:
						if $EvilDarel/darel_timer.is_stopped():
							$EvilDarel/darel_timer.start()
						$CanvasLayer/Main/Bossbar/ProgressBar/ProgressBar2.value = $EvilDarel/darel_timer.time_left
						$CanvasLayer/Main/Bossbar/ProgressBar/ProgressBar2.visible = true
					else:
						if !$EvilDarel/darel_timer.is_stopped():
							$EvilDarel/darel_timer.stop()
						$CanvasLayer/Main/Bossbar/ProgressBar/ProgressBar2.visible = false
				else:
					$CanvasLayer/Main/Bossbar/ProgressBar/ProgressBar2.visible = false
					
			
			
		if Input.is_action_just_pressed("jump"):
			if is_pacer_intro:
				$FakeFox/PacerTest/PacerStartTimer.stop()
				_on_pacer_start_timer_timeout()
		
		var total = 0
			
		for idd in players_ids:
			total += players[idd].books_collected
		total_books = total
		
		var vending_machines = get_tree().get_nodes_in_group("vending_machine")
		var broken_vending_machines = []
		 
		for vm in vending_machines:
			if vm is StaticBody3D:
				if vm.uses_left <= 0:
					if $Mr_Misuraca.global_position.distance_to(vm.global_position) < 2:
						vm.uses_left = 20
					else:
						broken_vending_machines.append(vm)
		
		if !is_misuraca_disabled:
			if broken_vending_machines.size() > 0:
				$Mr_Misuraca.update_target_location(broken_vending_machines[0].global_position)
				is_misuraca_fixing = true
			else:
				$Mr_Misuraca.go_back()
				is_misuraca_fixing = false
		else:
			$Mr_Misuraca.go_back()
			is_misuraca_fixing = false
		
		
		
		$Music2.pitch_scale = lerp($Music2.pitch_scale,float(music_pitch_target * music_pitch_boost),0.05)
		
		if total_books == books_to_collect - 1:
			if !absent:
				music_pitch_target = 1.5
		else:
			if !absent:
				music_pitch_target = 1
		
		update_player_text()
	
		players_in_lobby = players_ids.size()
		
		if Game.game_started:
			if !Allsingleton.is_bossfight:
				if !is_pacer:
					collected_books_label.text = str(total_books) + " books collected out of " + str(books_to_collect)
					if is_bet:
						collected_books_label.text += "\nBet: " + str(bet_books_left) + " left. Seconds left: " + str(floor($"Bet timer".time_left))
			else:
				collected_books_label.text = ""
		else:
			collected_books_label.text = "Find a ELA book!"
		leahy_speed = evil_leahy.SPEED
		
		$SubViewport/skibidiCamera.global_position = evil_leahy.global_position + Vector3(0,7,0)
		$SubViewport/skibidiCamera.global_rotation_degrees.x = -90
		$SubViewport/skibidiCamera.set_orthogonal(15,0.001,1000)
		

		
		if fox_follow && do_fox_help:
			mr_fox.update_target_location(book_pos)
		else:
			mr_fox.update_target_location(FOX_OG_POS)
			
		if gainy_attack:
			if gainy_target:
				ms_gainy.update_target_location(gainy_target.global_position)
				if players[gainy_target.name.to_int()].is_dead:
					gainy_attack = false
					gainy_target = null
					
		else:
			ms_gainy.go_back()

	if !Allsingleton.is_bossfight:
		if Game.game_started and multiplayer.is_server() and !absent:
			if !leahy_appeased:
				if !Game.powered_off:
					if !is_leahy_baja_blast:
						var closest = null
						var closest_distance = INF
						
						for p in players_ids:
							if !players[p].is_dead:
								var distance = evil_leahy.global_position.distance_to(get_node(str(p)).global_position)
								var showed_distance = evil_leahy.distance_to_target
								update_approching_label.rpc_id(p,showed_distance)
							
								if distance < closest_distance:
									closest = get_node(str(p)).global_position
									closest_distance = distance
									show_approaching_label.rpc_id(p)
								else:
									hide_approaching_label.rpc_id(p)
							else:
								hide_approaching_label.rpc_id(p)
						
						if closest:
							evil_leahy.update_target_location(closest)
							leahy_p_timeout = 0
						else:
							
							leahy_p_timeout += delta
							if leahy_p_timeout < 5:
								evil_leahy.update_target_location(evil_leahy.global_position)
							else:
								evil_leahy.update_target_location(mr_azzu.global_position)
					else:
						# baja blast
						
						var bathrooms = $"School/Bathroom spawns".get_children()
						
						var clst_dist = INF
						var clst_bathroom = null
						
						for bathroom : Node3D in bathrooms:
							var dst = evil_leahy.global_position.distance_to(bathroom.global_position)
							if dst < clst_dist:
								clst_dist = dst
								clst_bathroom = bathroom
						
						evil_leahy.update_target_location(clst_bathroom.global_position)
						
						if clst_dist < 5 && leahy_baja_timer <= 15:
							leahy_baja_timer += delta
							print(leahy_baja_timer)
						
						if leahy_baja_timer >= 15:
							is_leahy_baja_blast = false
							leahy_baja_timer = 0
						
				else:
					evil_leahy.update_target_location($Breaker.global_position)
					hide_approaching_label.rpc()
					var breaker_dst = evil_leahy.global_position.distance_to($Breaker.global_position)
					if breaker_dst < 2:
						leahy_power_fix_num += delta
						if leahy_power_fix_num >= 3:
							toggle_power.rpc(true,false)
							leahy_power_fix_num = 0
						
			else:
				evil_leahy.update_target_location(evil_leahy.global_position)
	
	if multiplayer.has_multiplayer_peer() and !Game.game_started and multiplayer.is_server():
		var setting_nodes = get_tree().get_nodes_in_group("checkbox")
		
		var initial_nodes = 0
		var game_config_client = $CanvasLayer/Lobby/Label4/gameConfigClient
		game_config_client.text = ""
		
		for setting in setting_nodes:
			if typeof(setting.initial_state) == TYPE_STRING:
				if !setting.is_neutral:
					if setting.initial_state.to_float() == setting.get_da_val():
						initial_nodes += 1
				else:
					initial_nodes += 1
				if setting.initial_state.to_float() != setting.get_da_val():
					game_config_client.text += setting.label_text + ": " + str(setting.get_da_val()) + "\n"
			else:
				if !setting.is_neutral:
					if setting.initial_state == setting.get_da_val():
						initial_nodes += 1
				else:
					initial_nodes += 1
				
				if setting.initial_state != setting.get_da_val():
					game_config_client.text += setting.label_text + ": " + str(setting.get_da_val()) + "\n"
		
		
		if initial_nodes == setting_nodes.size():
			do_achievements = true
		else:
			do_achievements = false
		
		if game_config_client.text == "":
			game_config_client.text = "Config wasn't changed"
		
		$CanvasLayer/Lobby/achievement.visible = !do_achievements

func _input(event):
	if event.is_action_type():
		if event.is_action_pressed("fullscreen"):
			if Allsingleton.is_fullscreen == false:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			
			Allsingleton.is_fullscreen = !Allsingleton.is_fullscreen

func _on_host_pressed():
	if !Allsingleton.non_steam:
		peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_FRIENDS_ONLY)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnect)
		_on_peer_connected()
	else:
		_on_host_local_pressed()


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
	$CanvasLayer/Lobby.show()
	$CanvasLayer/MultiPlayer.hide()
	
	if !multiplayer.is_server():
		$CanvasLayer/Lobby/ConfigPanel.hide()
	

@rpc("any_peer","call_local")
func receive_steam_usr(id,username):
	if !multiplayer.is_server(): return
	if players.has(id):
		players[id].username = username

func disconenct_btn():
	
	multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://game.tscn")

func _on_disconnect_from_server():
	pass
	
func go_back():
	get_tree().change_scene_to_file("res://game.tscn")

func _on_peer_connected(id = 1):
	#$CanvasLayer/MultiPlayer/LoadingRect.show()
	if !players_spawned:
		$CanvasLayer/Lobby.show()
		$CanvasLayer/MultiPlayer.hide()
		if multiplayer.is_server():
			$CanvasLayer/Lobby/Button7.show()
			$CanvasLayer/Lobby/Label4/reset_to_default.show()
			$CanvasLayer/Lobby/Label4/gameConfigClient.hide()
			is_in_lobby = true
	else:
		peer.disconnect_peer(id)
	
	
	players[id] = {
		"id":id,
		#"username":str(id),
		"books_collected":0,
		"is_dead":false,
		"deaths":0,
		"team":0,
		"finished_pacer":true
	}
	players_ids.append(id)
	books_to_collect += notebooks_per_player
	
	update_player_text()
	
	
	
	await get_tree().create_timer(1).timeout
	request_steam_usr.rpc_id(id)
	
	if Allsingleton.is_bossfight:
		pre_start_game_btn()
	

@rpc("any_peer","call_local")
func request_steam_usr():
	if !Allsingleton.non_steam:
		receive_steam_usr.rpc(peer.get_unique_id(),Steam.getPersonaName())
	else:
		receive_steam_usr.rpc(peer.get_unique_id(),OS.get_environment("USERNAME"))

func pre_start_game_btn():
	spawn_players()
	pre_start_game.rpc()
	if multiplayer.is_server():
		if !debug_host or !Allsingleton.non_steam:
			if lobby_id:
				Steam.setLobbyJoinable(lobby_id,false)
		
		var weather_chance = randi_range(0,20)
	
		print(weather_chance)
		if weather_chance < 2:
			set_fog_density.rpc(0.05)
		elif weather_chance < 5:
			set_fog_density.rpc(0.025)
		
		
		Game.set_pre_game_started.rpc()

func spawn_players():
	
	if !OS.has_feature("debug"):
		await get_tree().create_timer(8).timeout
	for pl_id in players_ids:
		var packed_player = preload("res://player.tscn")
		var player = packed_player.instantiate()

		player.set_multiplayer_authority(pl_id)
		player.name = str(pl_id)

		call_deferred("add_child",player,false)
		await get_tree().process_frame
		if !OS.has_feature("debug"):
			player.global_position = $"pre_start_game_anim/SCHOOL BUS/pl spawn".global_position + Vector3(randf_range(-3,3),0,randf_range(-3,3))
		
	players_spawned = true
	if do_vertical_camera:
		TipManager.show_tip_once.rpc("vertical_camera","[color=green][b]Super[/b] advanced camera[/color]\nSince you enabled it, suffer. To rotate the camera on the z axis, look north/south. To rotate the camera on the x axis, look east/west.",10)


@rpc("authority","call_local")
func set_fog_density(density):
	environment.volumetric_fog_density = density

@rpc("authority","call_local")
func pre_start_game():
	$CanvasLayer/Lobby.hide()
	$CanvasLayer/MultiPlayer.hide()
	$CanvasLayer/Main.show()
	$pre_start_game_anim/AnimationPlayer.play("pre")
	
	
	
func _on_peer_disconnect(id):
	if get_node_or_null(str(id)):
		get_node(str(id)).queue_free()
	
	players.erase(id)
	players_ids.erase(id)
	
	books_to_collect -= notebooks_per_player
	
	update_player_text()
	


func _on_connect_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost",7777)
	multiplayer.multiplayer_peer = peer

@rpc("any_peer","call_local")
func on_collect_book(id,book_name,personal):
	if multiplayer.is_server():
		var player_name
		if personal:
			player_name = get_node(str(id)).steam_name
		if book_name != "Landmine":
			if personal:
				players[id].books_collected += 1 + book_boost
			else:
				players[players.keys().pick_random()].books_collected += 1 + book_boost
			var total = 0
			
			for idd in players_ids:
				total += players[idd].books_collected
			
			if personal:
				var spawnpoint = book_spawns.get_children().pick_random()
				spawnpoint = spawnpoint.global_position
				book_pos = spawnpoint
				get_node(NodePath(book_name)).global_position = book_pos
			
			if total >= 3:
				remove_fence.rpc()
				TipManager.show_tip_once.rpc("gambling","[color=green]Gambling!!![/color]\n The fence around the item wheel is removed when you collect [b]3 notebooks[/b]. Go gamble.")
			
			if total == 1:
				if !Game.game_started:
					start_da_game.rpc()
					canPlayersMove = false
			elif total >= books_to_collect:
				if !Allsingleton.is_bossfight:
					var total_deaths = 0
					for idd in players_ids:
						total_deaths += players[idd].deaths
					
					if do_achievements:
						if total_deaths == 0:
							# impossible ending
							end_game.rpc("imp")
						elif total_deaths <= 3:
							# perfect run
							end_game.rpc("perfect")
						elif total_deaths > 3:
							if !do_vertical_camera:
								end_game.rpc("normal")
							else:
								end_game.rpc("disoriented")
					else:
						if !do_vertical_camera:
							end_game.rpc("normal")
						else:
							end_game.rpc("disoriented")
				
			
			total_books = total
			
			if players_in_lobby > 1:
				@warning_ignore("integer_division")
				evil_leahy.SPEED += (leahy_speed_per_notebook * (players_in_lobby / 2))
			else:
				evil_leahy.SPEED += leahy_speed_per_notebook
			
			if personal:
				info_text(player_name + " collected a book!")
			else:
				info_text("A book was collected!")
			fox_notebooks_left -= 1
			if fox_notebooks_left <= 0:
				fox_follow = false
				fox_notebooks_left = 0
				
			
			gainy_attack = false
			gainy_target = null
			split_for_everyone.rpc()
			
			if is_bet:
				bet_books_left -= 1
				if bet_books_left <= 0:
					_on_bet_timer_timeout(true,true)
			
			if Allsingleton.is_bossfight:
				evil_darel.health -= 5
			
		else:
			info_text(player_name + " slipped")
			var spawnpoint = $School/LandMineSpawns.get_children().pick_random()
			spawnpoint = spawnpoint.global_position
			spawnpoint.y = 0.143
			$Landmine.position = spawnpoint

@rpc("authority","call_local")
func remove_fence():
	if get_node_or_null("wheel/Fence"):
		$wheel/Fence.queue_free()

@rpc("any_peer","call_local")
func split_for_everyone():
	if enable_live_split:
		LiveSplit.start_or_split()


@rpc("any_peer","call_local")
func use_vending_machine(id,machine_name,item_weights):
	if !multiplayer.is_server(): return
	var vending_machine = get_node("School/Navigation").get_node(NodePath(machine_name))
	if !vending_machine: return
	
	if Game.game_started:
		for child in get_children():
			if child.name == str(id):
				if vending_machine.uses_left >= 0:
					if vending_machine.override_drops:
						
						var vending_machine_weights : Dictionary = vending_machine.overriden_drops
						var new_weights = item_weights
						
						for key in vending_machine_weights.keys():
							if new_weights[str(key)] != vending_machine_weights[str(key)]:
								new_weights[str(key)] = vending_machine_weights[str(key)]
						
						var item = pick_random_weighted(new_weights)
						
						child.choose_item.rpc_id(id,int(item),true)
						vending_machine.uses_left -= 1
					else:
						child.choose_item.rpc_id(id,-1,true)
						vending_machine.uses_left -= 1
					break
	
	else:
		for child in get_children():
			if child.name == str(id):
				if vending_machine.uses_left >= 0:
					child.choose_item.rpc_id(id,2,true)
					vending_machine.uses_left -= 1
					break

func pick_random_weighted(items_chances: Dictionary) -> Variant:
	# Calculate the total weight
	var total_weight = 0.0
	for weight in items_chances.values():
		total_weight += weight
	
	# Pick a random value within the range of total_weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	# Iterate through the dictionary to find the item
	for item in items_chances.keys():
		cumulative_weight += items_chances[item]
		if random_value <= cumulative_weight:
			return item
	
	# Fallback in case of rounding errors
	return items_chances.keys()[-1]

@rpc("authority","call_local")
func start_da_game():
	$bum.play()
	$Music1.stop()
	if !Allsingleton.is_bossfight:
		$Music2/Timer.start()
	else:
		$Music2/Timer.start(0.01)
	$WelcomeLeahy.hide()
	if !Allsingleton.is_bossfight:
		$WelcomeLeahy/AudioStreamPlayer3D.stop()
		$CanvasLayer/Main/LeahyAngeredLabel.show()
		evil_leahy.show()
		$grrrrrr.play()
		$EvilLeahy/AudioStreamPlayer3D.play()
	else:
		$CanvasLayer/Glitch.hide()

	
	if multiplayer.is_server():
		if !debug_host or !Allsingleton.non_steam:
			Steam.setLobbyJoinable(lobby_id,false)
		if !Allsingleton.is_bossfight:
			leahy_look = true
			$GainyTimer.start(gainy_attack_interval)

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
	if multiplayer.is_server():
		canPlayersMove = true
		Game.set_game_started.rpc()
		leahy_look = false
		$FakeFox/AnimationPlayer.play("new_animation")
		evil_leahy.SPEED = leahy_start_speed
		if !Allsingleton.is_bossfight:
			$Absences.start(absence_interval)
		
		if Allsingleton.is_bossfight:
			$School.toggle_ceiling(false)
			do_vertical_camera_normal = true
			$EvilDarel.show()
			$CanvasLayer/Main/Bossbar.show()
			$CanvasLayer/ColorRect/AnimationPlayer.play("bomboklatz")
			TipManager.show_tip("[color=green]Movement[/color]\nPress [b]space[/b] to jump [color=orange]//[/color] press [b]F key[/b] to punch [color=orange]//[/color] look up and down with [b]mouse[/b]",7)
			
			var timer = Timer.new()
			add_child(timer)
			timer.start(10)
			await timer.timeout
			timer.queue_free()
			
			TipManager.show_tip("[color=green]Darel.png[/color]\nDamage [b]Darel.png[/b] with clorox wipes [color=orange]//[/color] by collecting books", 7)

@rpc("authority","call_local")
func update_approching_label(meters):
	$CanvasLayer/Main/TextureRect/Label.text = str(round(meters))

var friends_lobbies = {}

func get_friends_lobbies():
	var item_list : ItemList = $"CanvasLayer/MultiPlayer/ItemList"
	if Allsingleton.non_steam:
		item_list.clear()
		item_list.add_item("Steam was not found.")
		return
	friends_lobbies = {}
	
	#for child in $CanvasLayer/MultiPlayer/ScrollContainer/VBoxContainer.get_children():
	#	child.queue_free()
	item_list.clear()
	
	var friend_count = Steam.getFriendCount()
	
	var total_playing = 0

	for i in range(0,friend_count):
		var friend = Steam.getFriendByIndex(i,Steam.FRIEND_FLAG_ALL)
		var friend_name = Steam.getFriendPersonaName(friend)
		
		var game_played = Steam.getFriendGamePlayed(friend)
		
		if !game_played.is_empty():
			if game_played.id == OS.get_environment("SteamAppID").to_int():
				if game_played.lobby:
					#var btn = Button.new()
					#btn.text = "Join " + friend_name
					#btn.connect("pressed",Callable(self,"join_lobby").bind(game_played.lobby))
					
					var idx = item_list.add_item("Join " + friend_name)
					friends_lobbies[idx] = game_played.lobby
					
					#$CanvasLayer/MultiPlayer/ScrollContainer/VBoxContainer.add_child(btn)
					total_playing += 1
				
	if total_playing == 0:
		item_list.add_item("No friends are playing :(")
		
		#$CanvasLayer/MultiPlayer/ScrollContainer/VBoxContainer.add_child(label)


func _on_button_pressed():
	get_friends_lobbies()

@rpc("any_peer","call_local")
func set_player_dead(id,is_dead,do_deaths):
	if multiplayer.is_server():
		players[id].is_dead = is_dead
		if is_dead and do_deaths:
			
			if !Allsingleton.is_bossfight:
				players[id].deaths += 1
			var total_deaths = 0
			for pl_id in players_ids:
				total_deaths += players[pl_id].deaths
			
			if !Allsingleton.is_bossfight:
				info_text(get_node(str(id)).steam_name + " dissapeared. " + str(total_deaths) + "/" + str(max_deaths + (deaths_per_player * players_in_lobby)))
			if is_pacer:
				stop_pacer.rpc()
			
			if !is_dp:
				if total_deaths >= (max_deaths + (deaths_per_player * players_in_lobby)):
					
					if total_books == 1:
						end_game.rpc("you suck")
					elif total_books > 1:
						end_game.rpc("worst")
					elif total_books == 0:
						end_game("dumb")
			else:
				end_game.rpc("none")


@rpc("any_peer","call_local")
func skibidi():
	if multiplayer.is_server():
		
		end_game.rpc("freaky")

var end_game_ending = ""
var players_singleton_ready = 0
var players_singleton_required = -1

@rpc("authority","call_local")
func end_game(ending : String):
	if multiplayer.is_server():
		end_game_ending = ending
		players_singleton_required = players.size() - 1
		players_singleton_ready = 0
		
		for id in players_ids:
			if id != 1:
				ping_set_singleton.rpc_id(id)
		
		if players_in_lobby > 1:
			while players_singleton_ready != players_singleton_required:
				await get_tree().create_timer(0.1).timeout
				print("waiting for players to disconnect")
			
			print("all players disconnected")

		if is_quitting:
			get_tree().quit()
		if players.has(1):
			set_singleton(players[1].deaths,players[1].books_collected,ending)
		

@rpc("authority","call_remote")
func ping_set_singleton():
	pong_set_singleton.rpc(peer.get_unique_id())

@rpc("any_peer","call_local")
func pong_set_singleton(id):
	if multiplayer.is_server():
		set_singleton.rpc_id(id,players[id].deaths,players[id].books_collected,end_game_ending)
		players_singleton_ready += 1

@rpc("authority","call_local")
func set_singleton(deaths,books,ending):
	EndGameSingleton.deaths = deaths
	EndGameSingleton.books_collected = books
	
	
	#peer.close()
	if ending == "normal":
		get_tree().change_scene_to_file("res://end.tscn")
	elif ending == "worst":
		get_tree().change_scene_to_file("res://bad_end.tscn")
	elif ending == "perfect":
		get_tree().change_scene_to_file("res://perfect_end.tscn")
	elif ending == "imp":
		get_tree().change_scene_to_file("res://impossible_end.tscn")
	elif ending == "freaky":
		
		var can_bossfight = false
		
		if Achievements.check_achievement("impossible_ending"):
			if Achievements.check_achievement("perfect_ending"):
				if Achievements.check_achievement("freaky_ending"):
					if Achievements.check_achievement("disoriented_ending"):
						if Achievements.check_achievement("good_ending"):
							if Achievements.check_achievement("bad_ending"):
								can_bossfight = true
								pass
		
		if !can_bossfight:
			get_tree().change_scene_to_file("res://huh_ending.tscn")
		else:
			get_tree().change_scene_to_file("res://huh_ending_2.tscn")
	elif ending == "you suck":
		get_tree().change_scene_to_file("res://worst_end.tscn")
	elif ending == "dumb":
		get_tree().change_scene_to_file("res://dumb_ahh_end.tscn")
	elif ending == "br":
		get_tree().change_scene_to_file("res://sadge.tscn")
	elif ending == "disoriented":
		get_tree().change_scene_to_file("res://disoriented_end.tscn")
	else:
		get_tree().change_scene_to_file("res://logos.tscn")
	peer.close()

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

func hide_menu():
	$CanvasLayer/MultiPlayer.hide()
	$Music1.play()
	$Music0.stop()


func _on_button_4_pressed():
	get_tree().change_scene_to_file("res://angy_azzu.tscn")

@rpc("any_peer","call_local")
func appease_leahy(username,sec):
	if multiplayer.is_server():
		if !do_leahy_appease: return
		
		$Appeasment.start(sec)
		leahy_appeased = true
		info_text(username + " appeased Leahy for "+str(sec)+" seconds.")


func _on_appeasment_timeout():
	if !is_pacer_intro:
		leahy_appeased = false

var fox_notebooks_left = 0

@rpc("any_peer","call_local")
func mr_fox_collect(is_sunkist):
	if multiplayer.is_server():
		if do_fox_help:
			if !fox_follow:
				fox_follow = true
				if is_sunkist:
					fox_notebooks_left = 2
				else:
					fox_notebooks_left = 1
			else:
				fox_notebooks_left += 1
			info_text("Follow Mr.Fox to find " + str(fox_notebooks_left) + " notebooks!")


func _on_button_5_pressed():
	get_tree().change_scene_to_file("res://achievements.tscn")

@export var absent = false

func _on_absences_timeout():
	if !multiplayer.is_server() : return
	if !Game.game_started : return
	if !do_absences: return
	if Game.powered_off: return
	if Allsingleton.is_bossfight: return
	
	if randi_range(0,absence_chance) == 1: 
		set_absent.rpc(true)
		absent = true
		hide_approaching_label.rpc()
		info_text("Ms.Leahy is gone???")
		music_pitch_target = 0.5
		TipManager.show_tip_once.rpc("absences","[color=green]Absences[/color]\n\"Sometimes\", Ms.Leahy is absent. She is gone!!!!! Have fun, go nuts!")
	else:
		if absent == true:
			absent = false
			set_absent.rpc(false)
			info_text("Ms.Leahy is here nvm")
			music_pitch_target = 1
	
	$Absences.start(absence_interval)

@rpc("authority","call_local")
func set_absent(is_absent : bool):
	if is_absent:
		evil_leahy.visible = false
		$EvilLeahy/AudioStreamPlayer3D.stop()
	else:
		evil_leahy.visible = true
		$EvilLeahy/AudioStreamPlayer3D.play()

@rpc("any_peer","call_local")
func azzu_steal(launcher):
	
	if multiplayer.is_server() && canPlayersMove:
		if !do_azzu_steal: return
		
		info_text(get_node(str(launcher)).steam_name + " angered Mr.Azzu")
		mr_azzu.server_target = true
		mr_azzu.update_target_location(get_node(str(launcher)).global_position)
		
		azzu_angered = true

@rpc("any_peer","call_local")
func azzu_dont_steal():
	if multiplayer.is_server():
		canPlayersMove = true
		azzu_angered = false
		mr_azzu.server_target = false
		mr_azzu._on_timer_timeout()



@onready var current_pacer_target = $"School/Pacer/Pacer target"

func switch_pacer_target():
	if current_pacer_target.get_path() == $"School/Pacer/Pacer target".get_path():
		current_pacer_target = $"School/Pacer/Pacer target2"
	else:
		current_pacer_target = $"School/Pacer/Pacer target"

@rpc("any_peer","call_local")
func check_if_finished_pacer_lap(id,target_path):
	if multiplayer.is_server():
		print(target_path,current_pacer_target.get_path())
		if target_path == current_pacer_target.get_path():
			players[id.to_int()].finished_pacer = true
			print(id, "finished the pacer lap")
			
			
			set_pacer_target_visibility.rpc_id(id.to_int(),target_path,false)

@rpc("authority","call_local")
func set_pacer_target_visibility(target_path,visibility):
	get_node(target_path).visible = visibility

@rpc("authority","call_local")
func play_pacer_lap_sound():
	$FakeFox/PacerLap.play()

@rpc("authority","call_local")
func play_pacer_level_sound():
	$FakeFox/PacerLevel.play()

var is_test_active: bool = false


func run_pacer_test() -> void:
	var current_level: int = 1
	var current_shuttle: int = 1
	var total_laps: int = 0
	is_test_active = true
	const INITIAL_TIME: float = 9.0
	const DECREMENT: float = 0.5
	const SHUTTLES_PER_LEVEL: int = 7

	while is_test_active:
		var time_for_shuttle: float = INITIAL_TIME - (current_level - 1) * DECREMENT
		print("Level: %d, Shuttle: %d, Time: %.1f seconds" % [current_level, current_shuttle, time_for_shuttle])
		play_pacer_lap_sound.rpc()
		collected_books_label.text = "Level " + str(current_level) + "\nLap " + str(total_laps)
		
		for p in players.keys():
			var pl = players[p]
			
			pl.finished_pacer = false
		
		await get_tree().create_timer(time_for_shuttle).timeout

		total_laps += 1
		current_shuttle += 1

		if current_shuttle > SHUTTLES_PER_LEVEL:
			# Level up
			current_level += 1
			current_shuttle = 1
			play_pacer_level_sound.rpc()
			info_text("Level " + str(current_level))
		
		if total_laps % 10 == 0:
			on_collect_book(-1,"",false)
		
		for p in players.keys():
			var pl = players[p]
			
			if pl.finished_pacer == false:
				get_node(str(p)).die.rpc_id(p,"fox")
		
		switch_pacer_target()
		set_pacer_target_visibility.rpc(current_pacer_target.get_path(),true)

@rpc("any_peer","call_local")
func start_da_pacer(id = -1):
	if is_pacer: return
	if is_pacer_intro: return
	
	# For everyone
	$FakeFox/PacerTest.play()
	$Music2.stop()
	$FakeFox.show()
	$"Mr Fox".hide()
	$"Mr Fox".mute = true
	
	
	
	# Server only
	if multiplayer.is_server():
		for pl in players_ids:
			get_node(str(pl)).server_pos.rpc_id(pl,$PacerPos.global_position + Vector3(randf_range(-10,10),0,randf_range(-10,10)))
		
		if id != -1:
			var username = get_node(str(id)).steam_name
			info_text(username + " angered Mr.Fox...")
		else:
			info_text("Mr.Fox is angry...")
		leahy_appeased = true
		$FakeFox/PacerTest/PacerStartTimer.start()
		canPlayersMove = false
		is_pacer_intro = true
		$"Bet timer".paused = true
		hide_approaching_label.rpc()
		
		TipManager.show_tip_once.rpc("pacer_test","[color=green]Pacer test[/color]\nEvery lap go to the [b]blue targets[/b]. You will get a notebook [b]every 10 laps.[/b] If [b]any[/b] player fails, the test is over.", 10)

func _on_pacer_start_timer_timeout():
	canPlayersMove = true
	is_pacer = true
	info_text("Pacer test started!")
	$FakeFox/PacerTest/PacerStartTimer2.start()
	is_pacer_intro = false
	
	set_pacer_target_visibility.rpc(current_pacer_target.get_path(),true)
	after_pacer_intro_end.rpc()
	run_pacer_test()

@rpc("authority","call_local")
func after_pacer_intro_end():
	$FakeFox/PacerTest.stop()
	$FakeFox/PacerMusic.play()

func _on_pacer_start_timer_2_timeout():
	pacer_deadly = true

@rpc("authority","call_local")
func stop_pacer():
	$FakeFox/PacerTest.stop()
	$Music2.play()
	$FakeFox.hide()
	$FakeFox/AnimationPlayer.speed_scale = 1
	$"Mr Fox".show()
	$"Mr Fox".mute = false
	$FakeFox/PacerMusic.stop()
	
	if multiplayer.is_server():
		is_pacer = false
		is_pacer_intro = false
		pacer_deadly = false
		leahy_appeased = false
		is_test_active = false
		
		$"Bet timer".paused = false
		$FakeFox/PacerTest/PacerStartTimer.stop()
		$FakeFox/PacerTest/PacerStartTimer2.stop()
		set_pacer_target_visibility.rpc($"School/Pacer/Pacer target".get_path(),false)
		set_pacer_target_visibility.rpc($"School/Pacer/Pacer target2".get_path(),false)

var penalties = {
	"EvilLeahy": 0,
	"Mr_Azzu": 0,
	"Mr Fox": 0,
	"Ms_Gainy": 0,
	"Mr_Misuraca": 0
}
var last_poses = {
	"EvilLeahy": Vector3(),
	"Mr_Azzu": Vector3(),
	"Mr Fox": Vector3(),
	"Ms_Gainy": Vector3(),
	"Mr_Misuraca": Vector3()
}

func _on_leahy_pos_diff_timeout():
	if !multiplayer.has_multiplayer_peer(): return
	if !multiplayer.is_server(): return
	if !Game.game_started: return
	
	for teacher in penalties:
		var diff = last_poses[teacher].distance_to(get_node(teacher).global_position)
		last_poses[teacher] = get_node(teacher).global_position
		if diff > 1:
			penalties[teacher] = 0
		else:
			if teacher == "Ms_Gainy":
				if gainy_target:
					penalties[teacher] += 1
			elif teacher == "Mr Fox":
				if fox_notebooks_left > 0:
					penalties[teacher] += 1
			elif teacher == "EvilLeahy":
				if !is_leahy_baja_blast:
					if !leahy_appeased:
						if !absent:
							penalties[teacher] += 1
			elif teacher == "Mr_Misuraca":
				if $Mr_Misuraca.angerer or is_misuraca_fixing:
					penalties[teacher] += 1
			else:
				penalties[teacher] += 1
		
		if penalties[teacher] > 7:
			var min_dst = 99999
			var cls_pos = Vector3(0,0,0)
			for respawn_pos : Node3D in $School/LeahyPenaltyPos.get_children():
				var dst = get_node(teacher).global_position.distance_to(respawn_pos.global_position)
				if dst < min_dst:
					cls_pos = respawn_pos.global_position
					min_dst = dst
		
			get_node(teacher).global_position = cls_pos
			penalties[teacher] = 0


func _on_open_config_pressed():
	$CanvasLayer/MultiPlayer/ConfigPanel.visible = !$CanvasLayer/MultiPlayer/ConfigPanel.visible


func _on_reset_to_default_pressed():
	var checkboxes = get_tree().get_nodes_in_group("checkbox")
	
	for checkbox in checkboxes:
		checkbox.go_to_inital()


func _on_button_6_pressed():
	get_tree().quit()

func update_player_text():
	var final_text = ""
	for pl_id in players_ids:
		if players[pl_id].has("username"):
			final_text += players[pl_id].username + "\n"
		else:
			final_text += str(pl_id) + "\n"
	player_list_text.text = final_text

var gainy_attack = false
@onready var ms_gainy = $Ms_Gainy
var gainy_target


func _on_gainy_timer_timeout():
	if Allsingleton.is_bossfight: return
	if multiplayer.is_server():
		$GainyTimer.start(gainy_attack_interval)
		if (!do_gainy_spawn): return
		if (is_pacer_intro): return
		
		
		if randi_range(0,gainy_attack_chance) == 1:
			gainy_attack_func()

func gainy_attack_func():
	gainy_attack = true
	var pls = get_tree().get_nodes_in_group("player")
	
	var just_some_random_guy = pls.pick_random()
	
	ms_gainy.update_target_location(just_some_random_guy.global_position)
	
	gainy_target = just_some_random_guy
	
	info_text("Ms.Gainy is angry at " + just_some_random_guy.steam_name)

@rpc("any_peer","call_local")
func stop_gainy(id):
	if multiplayer.is_server():
		if gainy_target:
			if gainy_target.name.to_int() == id:
				gainy_target.die.rpc_id(gainy_target.name.to_int(),"gainy")
				
				gainy_attack = false
				gainy_target = null


func _on_item_list_item_clicked(index, _at_position, mouse_button_index):
	if mouse_button_index != 1: return
	if friends_lobbies.has(index):
		join_lobby(friends_lobbies[index])


func _on_auto_refresh_timeout():
	get_friends_lobbies()


func _on_leahy_cool_timer_timeout():
	$EvilLeahy/AudioStreamPlayer3D.pitch_scale = randf_range(0.75,1.75)

@rpc("any_peer","call_local")
func play_coffee():
	$CoffeMachine/coffee.play()


@rpc("any_peer","call_local")
func boost_leahy(pl):
	if multiplayer.is_server():
		evil_leahy.SPEED *= 1.5
		book_boost += 0.5
		music_pitch_boost += 0.25
		info_text(pl + " gave Ms.Leahy Redbull...")

@rpc("any_peer","call_local")
func spawn_puddle(pos):
	var puddle = load("res://puddle.tscn").instantiate()
	add_child(puddle,true)
	puddle.global_position = pos

@rpc("any_peer","call_local")
func stop_misuraca():
	if multiplayer.is_server():
		$Mr_Misuraca.angerer = null

var is_bet = false
var bet_books_left = -1
var bet_loss = -1
var bet_reward = -1

@rpc("any_peer","call_local")
func do_bet(pl_name,books,time,loss,reward,item_name):
	if !multiplayer.is_server(): return
	
	is_bet = true
	bet_books_left = books
	$"Bet timer".start(time)
	bet_loss = loss
	bet_reward = reward
	
	info_text(pl_name + " started a bet. Win to get a " + item_name)

var is_dp = false

@rpc("authority","call_local")
func depression_ending():
	var dp = $"CanvasLayer/Main/fake dp ending"
	$"CanvasLayer/Main/fake dp ending/AnimationPlayer".play("fake dp ending")
	dp.show()
	
	$Music2.volume_db = -80
	environment.background_energy_multiplier = 0.25
	await get_tree().create_timer(9).timeout
	environment.background_energy_multiplier = 1
	await get_tree().create_timer(2).timeout
	if multiplayer.is_server():
		canPlayersMove = false
		is_dp = true
		evil_leahy.SPEED += 30
	

func loose_notebooks(books_loss):
	for p in players.keys():
		print(players[p])
		players[p].books_collected -= books_loss / players_in_lobby
	
	var total = 0
	for p in players.keys():
		total += players[p].books_collected
	
	if total < 0:
		#end_game.rpc("br")
		depression_ending.rpc()

func _on_bet_timer_timeout(overwrite : bool = false,won : bool = false):
	if !multiplayer.is_server(): return
	is_bet = false
	if bet_books_left > 0 or (overwrite and won == false):
		info_text("You lost the bet")
		loose_notebooks(bet_loss)
		bet_books_left = -1
		$"Bet timer".stop()
		

		
		
	elif bet_books_left <= 0 or (overwrite and won == true):
		info_text("You won the bet")
		
		for p in players.keys():
			get_node(str(p)).choose_item.rpc_id(p,bet_reward)
		
		$"Bet timer".stop()

@rpc("any_peer","call_local")
func spawn_dropped_item(pos,cloned_item,item_id):
	if multiplayer.is_server():
		var dropped_item = load("res://dropped_item.tscn").instantiate()
		add_child(dropped_item,true)
		dropped_item.global_position = pos
		dropped_item.item = item_id
		
		add_item_to_dropped.rpc(dropped_item.get_path(),cloned_item)
		
		if item_id == 4:
			if randi_range(0,15) == 1:
				start_da_pacer.rpc()

@rpc("authority","call_local")
func add_item_to_dropped(dropped_item_path,item_path):
	var clone = get_node(item_path).duplicate()
	
	get_node(dropped_item_path).add_child(clone)
	
	clone.position = Vector3(0,0,0)

@rpc("any_peer","call_local")
func remove_dropped_item(path):
	if multiplayer.is_server():
		if get_node(path):
			get_node(path).queue_free()


@rpc("any_peer","call_local")
func push_item(collider,push_direction,push_force):
	if multiplayer.is_server():
		if get_node(collider):
			get_node(collider).apply_central_impulse(-push_direction * push_force)

@export var noise_points = []

@rpc("any_peer","call_local")
func add_noise_point(pos):
	if multiplayer.is_server():
		noise_points.append(pos)

@rpc("any_peer","call_local")
func do_baja(steam_name):
	if multiplayer.is_server():
		is_leahy_baja_blast = true
		info_text(steam_name + " gave Ms.Leahy baja blast...")

@rpc("any_peer","call_local")
func set_door_state(door_path,open):
	if multiplayer.is_server():
		if get_node(door_path):
			get_node(door_path).set_open.rpc(open)
			
@rpc("any_peer","call_local")
func play_the_j():
	$Videoplayer.play()

@rpc("any_peer","call_local")
func play_sound(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20,pos = Vector3()):
	if !multiplayer.is_server(): return
	
	var a = load("res://player_sound.tscn").instantiate()
	add_child(a,true)
	
	var audio_stream : AudioStream = load(stream_path)
	
	
	actually_play_sound.rpc(a.get_path(),stream_path,volume_db,bus,max_distance,pos)
	
	await get_tree().create_timer(audio_stream.get_length()).timeout
	a.queue_free()

@rpc("authority","call_local")
func actually_play_sound(sound_path, stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20,pos = Vector3()):
	var sound = get_node(sound_path)
	if sound:
		sound.stream = load(stream_path)
		sound.bus = bus
		sound.max_distance = max_distance
		sound.volume_db = volume_db
		sound.global_position = pos
		sound.play()


@rpc("any_peer","call_local")
func spawn_smoke(pos):
	if multiplayer.is_server():
		var smoke = load("res://smoke wall.tscn").instantiate()
		$School/Navigation.add_child(smoke,true)
		smoke.global_position = pos
		smoke.navigation_mesh = $School/Navigation


func give_item_to_everyone(item_id):
	for pl in players.keys():
		get_node(str(pl)).choose_item.rpc_id(pl,item_id,true)

func reload_game():
	get_tree().change_scene_to_file("res://logos.tscn")

func _on_darel_timer_timeout():
	get_tree().get_first_node_in_group("player").die("darel")

func darel_phase2_transition():
	$Music2.stop()
	$EvilDarel/darel_timer.stop()
	$CanvasLayer/ColorRect/AnimationPlayer.play("bomboklatz")

func darel_phase2_start():
	$Music2.stream = load("res://dariel/placeholders/versus_loop.mp3")
	$Music2.play()

var is_quitting = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().auto_accept_quit = false
		
		if not is_quitting:
			is_quitting = true
			if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and Game.pre_game_started:
				end_game.rpc("none")
			else:
				get_tree().quit()
		
