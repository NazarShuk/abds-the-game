extends ColorRect

@onready var player = $"../../.."

var enable_livesplit = true

var previous_mouse
var previous_cam

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		toggle_menu()
	
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.can_cam_move = false
	

func toggle_menu():
	if visible == false:
		previous_mouse = Input.mouse_mode
		previous_cam = player.can_cam_move
	visible = !visible
	
	

	if visible == true:
		player.can_cam_move = !visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player.get_parent().players_in_lobby == 1:
			get_tree().paused = true
			if Game.collected_books >= 1:
				if enable_livesplit:
					LiveSplit.pause()
	else:
		
		if player.is_minimap_open:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			player.can_cam_move = false
		elif player.is_shop_open:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			player.can_cam_move = false
		elif $"../paper".visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			player.can_cam_move = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			player.can_cam_move = true
		
		get_tree().paused = false
		if Game.collected_books >= 1:
			if enable_livesplit:
				LiveSplit.resume()


func _on_disconnect_btn_pressed():
	$Main/DisconnectBtn.disabled = true
	get_tree().paused = false
	if !multiplayer.is_server():
		if multiplayer.has_multiplayer_peer():
			multiplayer.multiplayer_peer.close() # whyyy
		
		get_tree().change_scene_to_file("res://logos.tscn")
	else:
		player.get_parent().end_game.rpc("none")


func _on_enable_live_split_toggled(toggled_on):
	enable_livesplit = toggled_on
	LiveSplit.enable_live_split = toggled_on
