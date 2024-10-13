extends Node2D


func _ready():
	Settings.load_values_and_apply()
	Game.reset_values()
	
	AudioServer.set_bus_solo(6,false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	Allsingleton.menu_music_duration = 0

func _on_timer_timeout():
	multiplayer.multiplayer_peer = null
	#get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
