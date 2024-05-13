extends Node3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)


func _on_timer_timeout():
	get_tree().change_scene_to_file("res://game.tscn")
