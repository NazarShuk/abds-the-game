extends Node2D


func _ready():
	Settings.load_values_and_apply()

func _on_timer_timeout():
	multiplayer.multiplayer_peer = null
	#get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	
	get_tree().change_scene_to_file.call_deferred("res://game.tscn")

