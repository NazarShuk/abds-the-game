extends Node2D


func _ready():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	
	Settings.load_values_and_apply()
	Game.reset_values()
	
	AudioServer.set_bus_solo(6,false)
	GuiManager.reset_cursor()
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	GlobalVars.menu_music_duration = 0
	
	
	

func _on_timer_timeout():

	
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
