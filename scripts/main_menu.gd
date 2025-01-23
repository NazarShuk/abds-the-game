extends Node3D

var peer
@onready var loading: ColorRect = $CanvasLayer/Loading


func _ready() -> void:
	$AudioStreamPlayer.play(GlobalVars.menu_music_duration)
	GuiManager.show_cursor()
	
	if OS.has_feature("dedicated_server"):
		_on_host_local_pressed()

func _on_achievements_pressed():
	get_tree().change_scene_to_file.call_deferred("res://achievements.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file.call_deferred("res://settings.tscn")

func _on_play_pressed():
	host_lobby()

func _on_lobby_list_lobby_clicked(lobby_id):
	peer = ClassDB.instantiate("SteamMultiplayerPeer")
	GlobalVars.is_steam_peer = true
	loading.show()
	var err = peer.connect_lobby(lobby_id)
	print_rich("[color=orange]connecting via steam to lobby ", lobby_id)
	print("connect lobby err: ", err)
	
	if err == OK:
		Game.lobby_id = lobby_id
		print_rich("[color=green]joined lobby with id ",lobby_id, " changing scenes")
		load_main_game()
		

func host_lobby():
	loading.show()
	
	if SteamManager.steam_api:
		peer = ClassDB.instantiate("SteamMultiplayerPeer")
		GlobalVars.is_steam_peer = true
		peer.create_lobby(peer.LOBBY_TYPE_FRIENDS_ONLY)
		peer.lobby_created.connect(_on_lobby_created)
		
		print_rich("[color=orange]startig to open a lobby...")
		
	else:
		peer = OfflineMultiplayerPeer.new()
		
		print_rich("[color=green]opening game with an offline peer")
		load_main_game()

func _on_lobby_created(connect, lobby_id):
	if connect:
		Game.lobby_id = lobby_id
		SteamManager.steam_api.setLobbyData(lobby_id,"name",str(SteamManager.steam_name) + "'s lobby")
		SteamManager.steam_api.setLobbyJoinable(lobby_id,true)
		
		print_rich("[color=green]opening game with steam peer, lobby id: ", lobby_id)
		load_main_game()

func _on_host_local_pressed():
	peer = WebSocketMultiplayerPeer.new()
	peer.create_server(7777)
	
	load_main_game()

func _on_connect_local_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client($CanvasLayer/Control/Debug/LineEdit.text, 7777)
	
	load_main_game()

func _on_connect_local_2_pressed() -> void:
	peer = WebSocketMultiplayerPeer.new()
	peer.create_client($CanvasLayer/Control/Debug/LineEdit.text)
	
	load_main_game()

func _on_refresh_pressed() -> void:
	$CanvasLayer/Control/lobby_list.get_friends_lobbies()

func _exit_tree() -> void:
	GlobalVars.menu_music_duration = $AudioStreamPlayer.get_playback_position()
	

func load_main_game():
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_packed.call_deferred(GlobalVars.game_scene)
