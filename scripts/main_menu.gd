extends CanvasLayer

var peer
@onready var loading: ColorRect = $Loading

func _ready() -> void:
	$AudioStreamPlayer.play(Allsingleton.menu_music_duration)

func _on_achievements_pressed():
	get_tree().change_scene_to_file("res://achievements.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_play_pressed():
	host_lobby()

func _on_lobby_list_lobby_clicked(lobby_id):
	peer = SteamMultiplayerPeer.new()
	loading.show()
	var err = peer.connect_lobby(lobby_id)
	print_rich("[color=orange]connecting via steam to lobby ", lobby_id)
	print("connect lobby err: ", err)
	
	await Game.sleep(1)
	
	if err == OK:
		Game.lobby_id = lobby_id
		print_rich("[color=green]joined lobby with id ",lobby_id, " changing scenes")
		multiplayer.multiplayer_peer = peer
		get_tree().change_scene_to_file.call_deferred("res://game.tscn")
		

func host_lobby():
	if !Game.no_steam:
		peer = SteamMultiplayerPeer.new()
		peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_FRIENDS_ONLY)
		peer.lobby_created.connect(_on_lobby_created)
		
		print_rich("[color=orange]startig to open a lobby...")
		loading.show()
	else:
		peer = OfflineMultiplayerPeer.new()
		multiplayer.multiplayer_peer = peer
		print_rich("[color=green]opening game with an offline peer")
		loading.show()
		get_tree().change_scene_to_file.call_deferred("res://game.tscn")

func _on_lobby_created(connect, lobby_id):
	if connect:
		Game.lobby_id = lobby_id
		Steam.setLobbyData(lobby_id,"name",str(Steam.getPersonaName()) + "'s lobby")
		Steam.setLobbyJoinable(lobby_id,true)
		
		print_rich("[color=green]opening game with steam peer, lobby id: ", lobby_id)
		multiplayer.multiplayer_peer = peer
		get_tree().change_scene_to_file.call_deferred("res://game.tscn")

func _on_host_local_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer
	
	get_tree().change_scene_to_file.call_deferred("res://game.tscn")

func _on_connect_local_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1",7777)
	multiplayer.multiplayer_peer = peer
	
	get_tree().change_scene_to_file.call_deferred("res://game.tscn")

func _on_refresh_pressed() -> void:
	$Control/lobby_list.get_friends_lobbies()

func _exit_tree() -> void:
	Allsingleton.menu_music_duration = $AudioStreamPlayer.get_playback_position()
