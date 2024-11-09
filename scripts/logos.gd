extends Node2D

const main_game_path = "res://game.tscn"

func _ready():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	
	Settings.load_values_and_apply()
	Game.reset_values()
	
	AudioServer.set_bus_solo(6,false)

	GuiManager.force_cursor_state(true)
	
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	GlobalVars.menu_music_duration = 0
	
	if not GlobalVars.game_scene:
		ResourceLoader.load_threaded_request(main_game_path)
		var loading = true
		
		while loading:
			await Game.sleep(0.01)
			var progress = []
			
			ResourceLoader.load_threaded_get_status(main_game_path,progress)
			
			if progress[0] == 1:
				GlobalVars.game_scene = ResourceLoader.load_threaded_get(main_game_path)
				loading = false
	
	await Game.sleep(0.5)
	GuiManager.reset_cursor()
	
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
