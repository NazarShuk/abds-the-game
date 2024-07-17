extends ColorRect

@onready var player = $"../../.."

var enable_livesplit = true

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		toggle_menu()

func toggle_menu():
	visible = !visible
	player.can_cam_move = !visible

	if visible == true:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player.get_parent().players_in_lobby == 1:
			get_tree().paused = true
			if player.get_parent().total_books >= 1:
				if enable_livesplit:
					LiveSplit.pause()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false
		if player.get_parent().total_books >= 1:
			if enable_livesplit:
				LiveSplit.resume()


func _on_disconnect_btn_pressed():
	$Main/DisconnectBtn.disabled = true
	get_tree().paused = false
	if !multiplayer.is_server():
		multiplayer.multiplayer_peer.close()
		get_tree().reload_current_scene()
	else:
		player.get_parent().end_game.rpc("none")


func _on_enable_live_split_toggled(toggled_on):
	enable_livesplit = toggled_on
	player.get_parent().enable_live_split = toggled_on
