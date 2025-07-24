extends XROrigin3D

@export var main_menu : MainMenu

func _on_xr_controller_3d_button_pressed(button_name: String) -> void:
	match button_name:
		"trigger_click":
			if $XRController3D/RayCast3D.is_colliding():
				var collider = $XRController3D/RayCast3D.get_collider()
				
				if collider.name == "start_game":
					main_menu._on_play_pressed()
