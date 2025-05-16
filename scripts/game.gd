extends Node3D
class_name GameScene


var peer

@export var players_in_lobby = 0

@export var canPlayersMove = true

@export var leahy_look : bool

@export var pacer_available = true
@export var is_pacer = false
@export var pacer_deadly = false
var is_pacer_intro = false

@export var do_achievements = true

@onready var player_list_text = $CanvasLayer/Lobby/playerListText
var players_spawned = false

@export var is_in_lobby = false

var do_vertical_camera_normal = false

var music_pitch_target = 1
var music_pitch_boost = 1

@export var escape = false
@export var can_escape = false

var end_game_ending = ""
var players_singleton_ready = 0
var players_singleton_required = -1

@export var leahy_time = false

@export var competitive = false

const maps = {
	"large": {
		"scene": "res://school.tscn",
		"icon": preload("res://textures/large map.png"),
		"pacer": true
	},
	"small": {
		"scene": "res://old_school.tscn",
		"icon": preload("res://textures/small map.png"),
		"pacer": false
	}
}
@export var selected_map = "large"

var modes = {
	"normal": {
		"function": "normal_mode"
	},
	"scary": {
		"function": "scary_mode"
	}
}

func normal_mode():
	pass

func scary_mode():
	for breaker in get_tree().get_nodes_in_group("breaker"):
		breaker.queue_free()
	
	Game.environment.background_energy_multiplier = 0
	Game.sun.light_energy = 0
	$Music2.bus = "Mute Bus"
	$Music1.bus = "Mute Bus"
	
	AudioServer.set_bus_effect_enabled(2,1, true)

@export var selected_mode = "normal"

func _enter_tree():
	name = "MainGameScene"
func _exit_tree() -> void:
	AudioServer.set_bus_effect_enabled(2,1, false)

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.world_environment = $"Lighting and stuff/WorldEnvironment"
	Game.environment = Game.world_environment.environment
	Game.sun = $"Lighting and stuff/DirectionalLight3D"
	Game.on_book_collected.connect(_on_book_collected)
	
	Game.environment.background_energy_multiplier = 1
	Game.sun.light_energy = 1
	Game.environment.volumetric_fog_density = 0
	
	if Settings.render_distance:
		$pre_start_game_anim/Camera3D.far = Settings.render_distance
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	if Settings.better_lighting != null:
		Game.sun.visible = Settings.better_lighting
	
	
	prepare_multiplayer()
	$Music0.play(GlobalVars.menu_music_duration)
	GuiManager.reset_cursor()
	GuiManager.show_cursor()
	
	for key in maps:
		var map = maps[key]
		
		var button = Button.new()
		button.text = key.capitalize()
		button.icon = map.icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func ():
			selected_map = key
			$CanvasLayer/Lobby/map_choose/AnimationPlayer.play_backwards("open")
		)
		
		$CanvasLayer/Lobby/map_choose/Panel/horizontal.add_child(button)
	
	for key in modes:
		var mode = modes[key]
		
		var button = Button.new()
		button.text = key.capitalize()
		#button.icon = map.icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func ():
			selected_mode = key
			$CanvasLayer/Lobby/mode_choose/AnimationPlayer.play_backwards("open")
		)
		
		$CanvasLayer/Lobby/mode_choose/Panel/horizontal.add_child(button)


func prepare_multiplayer():
	peer = multiplayer.multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	multiplayer.server_disconnected.connect(_on_disconnected_from_server)
	
	if !OS.has_feature("dedicated_server"):
		_on_peer_connected()
	
func _on_network_session_failed(_steam_id: int, _reason: int, _connection_state: int):
	_on_disconnected_from_server()

func _on_disconnected_from_server():
	if !Game.did_finish:
		print_rich("[color=red] disconnected from server with no ending")
		get_tree().change_scene_to_file.call_deferred("res://logos.tscn")

func _on_book_collected(_amount):
	if !multiplayer.is_server(): return
	
	if is_bet:
		bet_books_left -= 1
		if bet_books_left <= 0:
			_on_bet_timer_timeout(true,true)
	
	if Game.collected_books == 1:
		if !Game.game_started:
			start_da_game.rpc()
			canPlayersMove = false
	elif Game.collected_books >= Game.books_to_collect and not competitive and not leahy_time:
		escape_mode.rpc()
	
	if leahy_time and Game.collected_books >= Game.books_to_collect:
		ending_check()
	
	if competitive:
		var teams = []
		
		for id in Game.players:
			if not teams.has(Game.players[id].team):
				teams.append(Game.players[id].team)
		
		for team in teams:
			var total_books = 0
			
			for id in Game.players:
				if Game.players[id].team == team:
					total_books += Game.players[id].books_collected
			
			if total_books == Game.books_to_collect:
				ending_check()
				break

func ending_check():
	var total_deaths = 0
	for idd in Game.players.keys():
		total_deaths += Game.players[idd].deaths
	
	var default_params = GameParams.new()
	
	for property in default_params.get_property_list():
		if property.name.begins_with("param_"):
			if default_params.get(property.name) != Game.game_params.get(property.name) and not default_params.neutral_parameters.has(property.name):
				do_achievements = false
				break
	
	if not competitive:
		if do_achievements:
			if not leahy_time:
				if total_deaths == 0:
					# impossible ending
					end_game.rpc("imp")
				elif total_deaths <= 3:
					# perfect run
					end_game.rpc("perfect")
				elif total_deaths > 3:
					if !Game.game_params.get_param("vertical_camera"):
						end_game.rpc("normal")
					else:
						end_game.rpc("disoriented")
			else:
				var time_left = $LeahyTime.time_left
				
				if time_left >= 100:
					end_game.rpc("leahy_time_p")
				elif time_left >= 75:
					end_game.rpc("leahy_time_s")
				elif time_left >= 50:
					end_game.rpc("leahy_time_a")
				elif time_left >= 30:
					end_game.rpc("leahy_time_b")
				elif time_left >= 15:
					end_game.rpc("leahy_time_c")
				else:
					end_game.rpc("leahy_time_d")
		else:
			end_game.rpc("normal")
	else:
		end_game.rpc("competitive")
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	Game.competitive = competitive
	
	if multiplayer.has_multiplayer_peer() && multiplayer.is_server():
		
		if Input.is_action_just_pressed("jump"):
			if is_pacer_intro:
				$FakeFox/PacerTest/PacerStartTimer.stop()
				_on_pacer_start_timer_timeout()
		
		Game.calculate_total_books()
		
		update_player_text()
	
		players_in_lobby = Game.players.keys().size()
		
		$CanvasLayer/Lobby/competitive.visible = players_in_lobby > 1
	
	if !Game.game_started:
		if competitive and $Music0.get("parameters/switch_to_clip") != "competitive":
			$Music0.set("parameters/switch_to_clip","competitive")
		if not competitive and  $Music0.get("parameters/switch_to_clip") != "normal":
			$Music0.set("parameters/switch_to_clip","normal")
		
		$CanvasLayer/Lobby/competitive_team_name.visible = competitive
		$CanvasLayer/Lobby/competitive_team_name.editable = competitive
		
		if !multiplayer.is_server():
			$CanvasLayer/Lobby/competitive.button_pressed = competitive
		
		$CanvasLayer/Lobby/TopContainer/map_button.text = selected_map.capitalize() + " map"
		$CanvasLayer/Lobby/TopContainer/map_button.icon = maps[selected_map].icon
		$CanvasLayer/Lobby/TopContainer/mode_button.text = selected_mode.capitalize() + " mode"
		#$CanvasLayer/Lobby/TopContainer/mode_button.icon = maps[selected_map].icon

func _input(event):
	if event.is_action_type():
		if event.is_action_pressed("fullscreen"):
			if GlobalVars.is_fullscreen == false:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			
			GlobalVars.is_fullscreen = !GlobalVars.is_fullscreen

func _on_connected_to_server():
	$CanvasLayer/Lobby.show()
	
	if !multiplayer.is_server():
		$CanvasLayer/Lobby/ConfigPanel.hide()
	
	if get_node_or_null("CanvasLayer/Lobby/book"):
		$CanvasLayer/Lobby/book.remove()
	if get_node_or_null("CanvasLayer/Lobby/cancel_button"):
		$CanvasLayer/Lobby/cancel_button.queue_free()

@rpc("any_peer","call_local")
func receive_steam_usr(id,username):
	if !multiplayer.is_server(): return
	if Game.players.has(id):
		Game.players[id].username = username

func disconenct_btn():
	multiplayer.multiplayer_peer.close()
	if peer is OfflineMultiplayerPeer:
		_on_disconnected_from_server()

func _on_peer_connected(id = 1):
	if !players_spawned:
		if multiplayer.is_server():
			$CanvasLayer/Lobby/Button7.show()
			$CanvasLayer/Lobby/Label4/reset_to_default.show()
			$CanvasLayer/Lobby/Label4/gameConfigClient.hide()
			is_in_lobby = true
			if get_node_or_null("CanvasLayer/Lobby/book"):
				$CanvasLayer/Lobby/book.remove()
			if get_node_or_null("CanvasLayer/Lobby/cancel_button"):
				$CanvasLayer/Lobby/cancel_button.queue_free()
	else:
		peer.disconnect_peer(id)
	
	
	Game.players[id] = {
		"id":id,
		"books_collected":0,
		"is_dead":false,
		"deaths":0,
		"team": "",
		"finished_pacer":true,
		"escaped": false
	}
	
	update_player_text()
	
	Game.sync_customization(id)
	
	await Game.sleep(1)
	request_steam_usr.rpc_id(id)
	Game.set_books_to_collect.rpc(Game.game_params.get_param("starting_notebooks") + (Game.players.keys().size()) * Game.game_params.get_param("notebooks_per_player"))
	if OS.has_feature("dedicated_server"):
		if Game.players.size() == 1:
			show_start_game_btn.rpc_id(Game.players.keys()[0])

@rpc("any_peer","call_local")
func request_steam_usr():
	receive_steam_usr.rpc(peer.get_unique_id(),SteamManager.steam_name)

func pre_start_game_btn():
	if multiplayer.is_server():
		spawn_players()
		pre_start_game.rpc()
		if multiplayer.is_server():
			if Game.lobby_id:
				SteamManager.steam_api.setLobbyJoinable(Game.lobby_id,false)
			
			var weather_chance = randi_range(0,20)
		
			print(weather_chance)
			if weather_chance < 2:
				set_fog_density.rpc(0.05)
			elif weather_chance < 5:
				set_fog_density.rpc(0.025)
			
			
			Game.set_pre_game_started.rpc()
			
			Game.set_books_to_collect.rpc(Game.game_params.get_param("starting_notebooks") + (Game.players.keys().size()) * Game.game_params.get_param("notebooks_per_player"))
	else:
		request_to_start_game.rpc(multiplayer.get_unique_id())

@rpc("authority","call_remote")
func show_start_game_btn():
	$CanvasLayer/Lobby/Button7.show()

@rpc("any_peer","call_local")
func request_to_start_game(id):
	if multiplayer.is_server():
		if OS.has_feature("dedicated_server"):
			if id == Game.players.keys()[0]:
				pre_start_game_btn()

func spawn_players():
	if !OS.has_feature("debug"):
		await Game.sleep(3)
	for pl_id in Game.players.keys():
		var player = load("res://player.tscn").instantiate()

		player.set_multiplayer_authority(pl_id)
		player.name = str(pl_id)
		
		call_deferred("add_child",player,false)
		await get_tree().process_frame
		
	players_spawned = true


@rpc("authority","call_local")
func set_fog_density(density):
	Game.environment.volumetric_fog_density = density

@rpc("authority","call_local")
func pre_start_game():
	$CanvasLayer/Lobby.hide()
	$CanvasLayer/Main.show()
	$pre_start_game_anim/AnimationPlayer.play("fall")
	$Music1.play()
	$Music0.stop()
	
	var school : Node3D = load(maps[selected_map].scene).instantiate()
	add_child(school)
	
	pacer_available = maps[selected_map].pacer
	if maps[selected_map].pacer:
		current_pacer_target = $"School/Pacer/Pacer target"
	
	call(modes[selected_mode].function)


func _on_peer_disconnect(id):
	if get_node_or_null(str(id)):
		get_node(str(id)).queue_free()
	
	Game.players.erase(id)
	
	Game.set_books_to_collect.rpc(Game.game_params.get_param("starting_notebooks") + (Game.players.keys().size()) * Game.game_params.get_param("notebooks_per_player"))
	
	update_player_text()
	
	if !multiplayer.is_server() and GlobalVars.is_steam_peer:
		if id == 1:
			_on_disconnected_from_server()
	
	if OS.has_feature("dedicated_server"):
		if Game.players.keys().size():
			print_rich("[color=red]All players left. Shutting down.")
			get_tree().quit()

@rpc("authority","call_local")
func start_da_game():
	$bum.play()
	$Music1.stop()
	
	if OS.has_feature("debug"):
		$Music2/Timer.start(0.01)
	else:
		$Music2/Timer.start()
	
	if multiplayer.is_server():
		if Game.lobby_id:
			SteamManager.steam_api.setLobbyJoinable(Game.lobby_id,false)
			leahy_look = true

func _on_timer_timeout():
	$Music2.play()
	
	if multiplayer.is_server():
		canPlayersMove = true
		Game.set_game_started.rpc()
		leahy_look = false
		$FakeFox/AnimationPlayer.play("new_animation")
		

@rpc("any_peer","call_local")
func set_player_dead(id,is_dead,do_deaths):
	if multiplayer.is_server():
		Game.players[id].is_dead = is_dead
		if is_dead and do_deaths:
			
			Game.players[id].deaths += 1
			var total_deaths = 0
			var dead_players = 0
			
			
			for pl_id in Game.players.keys():
				total_deaths += Game.players[pl_id].deaths
				if Game.players[pl_id].is_dead:
					dead_players += 1
			
			var is_eveyone_dead = dead_players == Game.players.keys().size() 
			
			
			
			
			Game.info_text(get_node(str(id)).steam_name + " dissapeared. " + str(total_deaths) + "/" + str(Game.game_params.get_param("max_deaths") + (Game.game_params.get_param("deaths_per_player") * players_in_lobby)))
			
			if not competitive:
				if !is_dp:
					if total_deaths >= (Game.game_params.get_param("max_deaths") + (Game.game_params.get_param("deaths_per_player") * players_in_lobby)) or (can_escape and is_eveyone_dead and not leahy_time):
						if Game.collected_books == 1:
							end_game.rpc("you suck")
						elif Game.collected_books > 1:
							end_game.rpc("worst")
						elif Game.collected_books == 0:
							end_game.rpc("dumb")
				else:
					end_game.rpc("none")


@rpc("any_peer","call_local")
func skibidi():
	if multiplayer.is_server():
		end_game.rpc("freaky")


var team_won = ""

@rpc("authority","call_local")
func end_game(ending : String):
	if multiplayer.is_server():
		
		var saved_players = Game.players.duplicate()
		
		end_game_ending = ending
		players_singleton_required = Game.players.size() - 1
		players_singleton_ready = 0
		
		for id in Game.players.keys():
			if id != 1:
				ping_set_singleton.rpc_id(id)
		
		if players_in_lobby > 1:
			while players_singleton_ready != players_singleton_required:
				await Game.sleep(0.5)
				print("waiting for players to get singletoned")
			
			print("all players disconnected")
		
		if Game.players.has(1):
			set_singleton(Game.players[1].deaths,Game.players[1].books_collected,ending, team_won)

@rpc("authority","call_remote")
func ping_set_singleton():
	pong_set_singleton.rpc(peer.get_unique_id())

@rpc("any_peer","call_local")
func pong_set_singleton(id):
	if multiplayer.is_server():
		
		var winner_team = ""
		if competitive:
			var teams = []
			for idx in Game.players:
				var player = Game.players[idx]
				if not teams.has(player.team):
					teams.append(player.team)
			
			for team in teams:
				var total_books = 0
				for idx in Game.players:
					var player = Game.players[idx]
					if player.team == team:
						total_books += player.books_collected
				
				if total_books == Game.books_to_collect:
					winner_team = team
					team_won = winner_team
					break
		
		set_singleton.rpc_id(id,Game.players[id].deaths,Game.players[id].books_collected,end_game_ending, winner_team)
		players_singleton_ready += 1

@rpc("authority","call_local")
func set_singleton(deaths,books,ending : String, competitive_team_won = ""):
	GlobalVars.deaths = deaths
	GlobalVars.books_collected = books
	GlobalVars.competitive_team_won = competitive_team_won
	Game.did_finish = true
	
	#peer.close()
	if ending == "normal":
		get_tree().change_scene_to_packed.call_deferred(load("res://end.tscn"))
	elif ending == "worst":
		get_tree().change_scene_to_packed.call_deferred(load("res://bad_end.tscn"))
	elif ending == "perfect":
		get_tree().change_scene_to_packed.call_deferred(load("res://perfect_end.tscn"))
	elif ending == "imp":
		get_tree().change_scene_to_packed.call_deferred(load("res://impossible_end.tscn"))
	elif ending == "freaky":
		var can_bossfight = false
		
		if Achievements.check_achievement("impossible_ending"):
			if Achievements.check_achievement("perfect_ending"):
				if Achievements.check_achievement("freaky_ending"):
					if Achievements.check_achievement("disoriented_ending"):
						if Achievements.check_achievement("good_ending"):
							if Achievements.check_achievement("bad_ending"):
								#can_bossfight = true
								pass
		
		if !can_bossfight:
			get_tree().change_scene_to_packed.call_deferred(load("res://huh_ending.tscn"))
		else:
			get_tree().change_scene_to_packed.call_deferred(load("res://scenes/bossfight.tscn"))
	elif ending == "you suck":
		get_tree().change_scene_to_packed.call_deferred(load("res://worst_end.tscn"))
	elif ending == "dumb":
		get_tree().change_scene_to_packed.call_deferred(load("res://dumb_ahh_end.tscn"))
	elif ending == "disoriented":
		get_tree().change_scene_to_packed.call_deferred(load("res://disoriented_end.tscn"))
	elif ending == "competitive":
		get_tree().change_scene_to_file.call_deferred("res://scenes/competitive_result.tscn")
	elif ending.begins_with("leahy_time_"):
		GlobalVars.leahy_time_rank = ending.replace("leahy_time_", "")
		get_tree().change_scene_to_file.call_deferred("res://scenes/pizza_end.tscn")
	else:
		get_tree().change_scene_to_file.call_deferred("res://logos.tscn")


var current_pacer_target

func switch_pacer_target():
	if current_pacer_target.get_path() == $"School/Pacer/Pacer target".get_path():
		current_pacer_target = $"School/Pacer/Pacer target2"
	else:
		current_pacer_target = $"School/Pacer/Pacer target"

@rpc("any_peer","call_local")
func check_if_finished_pacer_lap(id,target_path):
	if !pacer_available: return
	if multiplayer.is_server():
		print(target_path,current_pacer_target.get_path())
		if target_path == current_pacer_target.get_path():
			Game.players[id.to_int()].finished_pacer = true
			print(id, "finished the pacer lap")
			
			set_pacer_target_visibility.rpc_id(id.to_int(),target_path,false)

@rpc("authority","call_local")
func set_pacer_target_visibility(target_path,visibility):
	get_node(target_path).visible = visibility

@rpc("authority","call_local")
func play_pacer_lap_sound():
	if !pacer_available: return
	$FakeFox/PacerLap.play()

@rpc("authority","call_local")
func play_pacer_level_sound():
	if !pacer_available: return
	$FakeFox/PacerLevel.play()

var is_test_active: bool = false

@export var pacer_lap = 0
@export var pacer_level = 0

func run_pacer_test() -> void:
	if !pacer_available: return
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
		
		pacer_level = current_level
		pacer_lap = total_laps
		
		for p in Game.players.keys():
			var pl = Game.players[p]
			
			pl.finished_pacer = false
		
		await Game.sleep(time_for_shuttle)

		total_laps += 1
		current_shuttle += 1

		if current_shuttle > SHUTTLES_PER_LEVEL:
			# Level up
			current_level += 1
			current_shuttle = 1
			play_pacer_level_sound.rpc()
			Game.info_text("Level " + str(current_level))
		
		if total_laps % 10 == 0:
			var id = Game.players.keys().pick_random()
			
			Game.players[id].books_collected += 1 + Game.book_boost
			Game.calculate_total_books()
			Game.info_text("A book was collected")
		
		var did_someone_die = false
		
		for p in Game.players.keys():
			var pl = Game.players[p]
			
			if pl.finished_pacer == false:
				get_node(str(p)).die.rpc_id(p,"fox")
				did_someone_die = true
		
		if did_someone_die:
			stop_pacer.rpc()
		
		switch_pacer_target()
		set_pacer_target_visibility.rpc(current_pacer_target.get_path(),true)

@rpc("any_peer","call_local")
func start_da_pacer(id = -1):
	if !pacer_available: return
	
	if is_pacer: return
	if is_pacer_intro: return
	
	# For everyone
	$FakeFox/PacerTest.play()
	$Music2.stop()
	$FakeFox.show()
	
	var mr_fox = get_tree().get_first_node_in_group("mr_fox")
	if mr_fox:
		mr_fox.hide()
		mr_fox.mute = true
	
	# Server only
	if multiplayer.is_server():
		for pl in Game.players.keys():
			get_node(str(pl)).server_pos.rpc_id(pl,$PacerPos.global_position + Vector3(randf_range(-10,10),0,randf_range(-10,10)))
		
		if id != -1:
			var username = get_node(str(id)).steam_name
			Game.info_text(username + " angered Mr.Fox...")
		else:
			Game.info_text("Mr.Fox is angry...")
		
		for el in get_tree().get_nodes_in_group("evil_leahy"):
			el.appeased = true
		
		$FakeFox/PacerTest/PacerStartTimer.start()
		canPlayersMove = false
		is_pacer_intro = true
		$"Bet timer".paused = true
		
		GuiManager.show_tip_once.rpc("pacer_test","[color=green]Pacer test[/color]\nEvery lap go to the [b]blue targets[/b]. You will get a notebook [b]every 10 laps.[/b] If [b]any[/b] player fails, the test is over.", 10)

func _on_pacer_start_timer_timeout():
	if !pacer_available: return
	canPlayersMove = true
	is_pacer = true
	Game.info_text("Pacer test started!")
	$FakeFox/PacerTest/PacerStartTimer2.start()
	is_pacer_intro = false
	
	set_pacer_target_visibility.rpc(current_pacer_target.get_path(),true)
	after_pacer_intro_end.rpc()
	run_pacer_test()

@rpc("authority","call_local")
func after_pacer_intro_end():
	if !pacer_available: return
	$FakeFox/PacerTest.stop()
	$FakeFox/PacerMusic.play()

func _on_pacer_start_timer_2_timeout():
	pacer_deadly = true

@rpc("authority","call_local")
func stop_pacer():
	if !pacer_available: return
	$FakeFox/PacerTest.stop()
	$Music2.play()
	$FakeFox.hide()
	$FakeFox/AnimationPlayer.speed_scale = 1
	var mr_fox = get_tree().get_first_node_in_group("mr_fox")
	if mr_fox:
		mr_fox.show()
		mr_fox.mute = false
	$FakeFox/PacerMusic.stop()
	
	if multiplayer.is_server():
		is_pacer = false
		is_pacer_intro = false
		pacer_deadly = false
		
		for el in get_tree().get_nodes_in_group("evil_leahy"):
			el.appeased = false
		
		is_test_active = false
		
		$"Bet timer".paused = false
		$FakeFox/PacerTest/PacerStartTimer.stop()
		$FakeFox/PacerTest/PacerStartTimer2.stop()
		set_pacer_target_visibility.rpc($"School/Pacer/Pacer target".get_path(),false)
		set_pacer_target_visibility.rpc($"School/Pacer/Pacer target2".get_path(),false)

func update_player_text():
	var final_text = ""
	for pl_id in Game.players.keys():
		
		if competitive and Game.players[pl_id].team != "":
			final_text += "[%s] " % [Game.players[pl_id].team]
		
		if Game.players[pl_id].has("username"):
			final_text += Game.players[pl_id].username
		else:
			final_text += str(pl_id)
		final_text += "\n"
	player_list_text.text = final_text

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
	
	Game.info_text(pl_name + " started a bet. Win to get a " + item_name)

var is_dp = false

@rpc("authority","call_local")
func depression_ending():
	var dp = $"CanvasLayer/Main/fake dp ending"
	$"CanvasLayer/Main/fake dp ending/AnimationPlayer".play("fake dp ending")
	dp.show()
	
	$Music2.volume_db = -80
	Game.environment.background_energy_multiplier = 0.25
	await Game.sleep(9)
	Game.environment.background_energy_multiplier = 1
	await Game.sleep(2)
	if multiplayer.is_server():
		canPlayersMove = false
		is_dp = true
		for el in get_tree().get_nodes_in_group("evil_leahy"):
			el.SPEED += 30


func loose_notebooks(books_loss):
	for p in Game.players.keys():
		print(Game.players[p])
		Game.players[p].books_collected -= books_loss / players_in_lobby
	
	var total = 0
	for p in Game.players.keys():
		total += Game.players[p].books_collected
	
	if total < 0:
		depression_ending.rpc()

func _on_bet_timer_timeout(overwrite : bool = false,won : bool = false):
	if !multiplayer.is_server(): return
	is_bet = false
	if bet_books_left > 0 or (overwrite and won == false):
		Game.info_text("You lost the bet")
		loose_notebooks(bet_loss)
		bet_books_left = -1
		$"Bet timer".stop()
		
	elif bet_books_left <= 0 or (overwrite and won == true):
		Game.info_text("You won the bet")
		
		for p in Game.players.keys():
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
		
		if item_id == 4 and not competitive:
			if randi_range(0,15) == 1:
				start_da_pacer.rpc()

@rpc("authority","call_local")
func add_item_to_dropped(dropped_item_path,item_path):
	var clone = get_node(item_path).duplicate()
	
	get_node(dropped_item_path).add_child(clone)
	
	clone.position = Vector3(0,0,0)

func give_item_to_everyone(item_id):
	for pl in Game.players.keys():
		get_node(str(pl)).choose_item.rpc_id(pl,item_id,true)

func reload_game():
	get_tree().change_scene_to_file.call_deferred("res://logos.tscn")

@rpc("authority","call_local")
func escape_mode():
	if escape: return
	if can_escape: return
	if multiplayer.is_server():
		escape = true
	
	await Game.sleep(5)
	$Music2.stop()
	await Game.sleep(2)
	$escape.play()
	
	GuiManager.show_subtitle_for("Congratulations! You collected", 2.36)
	await Game.sleep(2.36)
	GuiManager.show_subtitle_for("All green ELA notebooks", 5.23 - 2.36)
	await Game.sleep(5.23 - 2.36)
	GuiManager.show_subtitle_for("Now all you have to do is...", 6.83 - 5.23)
	await Game.sleep(6.83 - 5.23)
	GuiManager.show_subtitle_for("Run.", 7.81 - 6.83)
	await Game.sleep(7.81 - 6.83)
	can_escape = true

@rpc("authority","call_local")
func leahy_time_mode():
	
	if !can_escape: return
	if leahy_time: return
	
	$escape.stop()
	leahy_time = true
	$CanvasLayer/Main/LeahyTime/AnimationPlayer.play("intro")
	$leahytime.play()
	
	$bum.play()
	
	$LeahyTime.start()
	if multiplayer.is_server():
		
		for idx in Game.players:
			Game.players[idx].books_collected = 0
			Game.calculate_total_books()

func _on_leahy_time_timeout() -> void:
	if multiplayer.is_server():
		end_game.rpc("worst")


func _on_competitive_toggled(toggled_on: bool) -> void:
	if multiplayer.is_server():
		competitive = toggled_on

@rpc("any_peer","call_local")
func change_theme(team_name : String):
	Game.players[multiplayer.get_remote_sender_id()].team = team_name.to_upper().strip_edges()

func _on_competitive_team_name_text_changed(new_text: String) -> void:
	change_theme.rpc_id(1, new_text)


func _on_map_button_pressed() -> void:
	if !multiplayer.is_server(): return
	$CanvasLayer/Lobby/map_choose/AnimationPlayer.play("open")


func _on_mode_button_pressed() -> void:
	if !multiplayer.is_server(): return
	$CanvasLayer/Lobby/mode_choose/AnimationPlayer.play("open")
