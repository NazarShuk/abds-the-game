extends Node3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	AudioServer.set_bus_solo(6,false)
	
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	
func go_back():
	get_tree().change_scene_to_file("res://game.tscn")

func anim_back():
	$CanvasLayer/AnimationPlayer.play("nein")
	$CanvasLayer/Dialog1.hide()
	$CanvasLayer/Dialog2.hide()


func _on_button_pressed():
	$CanvasLayer/AnimationPlayer.play("fight him")


func _on_butto22n_pressed():
	Allsingleton.is_bossfight = true
	$CanvasLayer/AnimationPlayer.play("final")
