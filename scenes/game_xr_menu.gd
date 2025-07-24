extends XROrigin3D

@export var game : GameScene

func _on_xr_controller_3d_button_pressed(button: String) -> void:
	match button:
		"ax_button":
			game.pre_start_game_btn()
