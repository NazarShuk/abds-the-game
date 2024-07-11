extends ColorRect

@onready var player = $"../../.."

func _process(delta):
	if Input.is_action_just_pressed("escape"):
		toggle_menu()

func toggle_menu():
	visible = !visible
	player.can_cam_move = !visible

	if visible == true:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player.get_parent().players_in_lobby == 1:
			get_tree().paused = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false


func _on_disconnect_btn_pressed():
	$Main/DisconnectBtn.disabled = true
	get_tree().paused = false
	if !multiplayer.is_server():
		print(name,"not server")
		multiplayer.multiplayer_peer.close()
		get_tree().reload_current_scene()
	else:
		player.get_parent().end_game.rpc("none")
