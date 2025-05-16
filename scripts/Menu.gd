extends ColorRect

@export var player : CharacterBody3D


var previous_mouse
var previous_cam

func _enter_tree() -> void:
	set_multiplayer_authority(player.name.to_int())

func _process(_delta):
	if Input.is_action_just_pressed("escape") and is_multiplayer_authority():
		toggle_menu()
	

func toggle_menu():
	if !is_multiplayer_authority(): return
	
	visible = !visible
	
	if visible == true:
		GuiManager.show_cursor()
		if player.get_parent().players_in_lobby == 1:
			get_tree().paused = true
	else:
		get_tree().paused = false
		GuiManager.hide_cursor()


func _on_disconnect_btn_pressed():
	$Main/DisconnectBtn.disabled = true
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")
