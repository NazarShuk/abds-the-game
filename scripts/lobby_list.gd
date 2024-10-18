extends ItemList

var friends_lobbies = {}

signal lobby_clicked(lobby_id : int)

func _ready():
	get_friends_lobbies()

func get_friends_lobbies():
	if Game.no_steam:
		clear()
		add_item("Steam was not found.")
		return
	
	friends_lobbies = {}
	
	clear()
	
	var friend_count = SteamManager.steam_api.getFriendCount()
	var total_playing = 0
	
	for i in range(0,friend_count):
		var friend = SteamManager.steam_api.getFriendByIndex(i,SteamManager.steam_api.FRIEND_FLAG_ALL)
		var friend_name = SteamManager.steam_api.getFriendPersonaName(friend)
		
		var game_played = SteamManager.steam_api.getFriendGamePlayed(friend)
		
		if !game_played.is_empty():
			if game_played.id == OS.get_environment("SteamAppID").to_int():
				if game_played.lobby:
					var idx = add_item("Join " + friend_name)
					friends_lobbies[idx] = game_played.lobby
					
					total_playing += 1
					print(friend_name)
				
	if total_playing == 0:
		add_item("No friends are playing :(")

func _on_auto_refresh_timeout():
	get_friends_lobbies()

func _on_item_clicked(index, _at_position, mouse_button_index):
	if mouse_button_index != 1: return
	
	if friends_lobbies.has(index):
		lobby_clicked.emit(friends_lobbies[index])
