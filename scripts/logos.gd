extends Node2D


func _ready():
	Settings.load_values_and_apply()

func _on_timer_timeout():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	
	get_tree().change_scene_to_file.call_deferred("res://game.tscn")

