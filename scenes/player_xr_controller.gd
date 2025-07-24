extends XROrigin3D

@export var player : Player

func _on_right_hand_button_pressed(button_name: String) -> void:
	print("[right hand, press] ", button_name)
	
	match button_name:
		"trigger_click":
			Input.action_press("give")
		"grip_click":
			Input.action_press("use_item")
		"ax_button":
			Input.action_press("interact")
	

func _on_right_hand_button_released(button_name: String) -> void:
	print("[right hand, release] ", button_name)
	
	match button_name:
		"trigger_click":
			Input.action_release("give")
		"grip_click":
			Input.action_release("use_item")
		"ax_button":
			Input.action_release("interact")
func _on_left_hand_button_pressed(button_name: String) -> void:
	print("[left hand, press] ", button_name)
	
	match button_name:
		"grip_click":
			Input.action_press("sprint")
	
func _on_left_hand_button_released(button_name: String) -> void:
	print("[left hand, release] ", button_name)
	
	match button_name:
		"grip_click":
			Input.action_release("sprint")

func _on_right_hand_input_vector_2_changed(vector_name: String, value: Vector2) -> void:
	print("[right hand] ", vector_name, ": ", value)
	match vector_name:
		"primary":
			if value.y > 0.5:
				Input.action_press("forward")
			if value.y < -0.5:
				Input.action_press("back")
			
			if value.y < 0.5 and value.y > -0.5:
				Input.action_release("forward")
				Input.action_release("back")
			
			if value.x > 0.5:
				Input.action_press("right")
			if value.x < -0.5:
				Input.action_press("left")
			
			if value.x < 0.5 and value.x > -0.5:
				Input.action_release("right")
				Input.action_release("left")

func _on_left_hand_input_vector_2_changed(vector_name: String, value: Vector2) -> void:
	print("[left hand] ", vector_name, ": ", value)
	
	match vector_name:
		"primary":
			player.rotate_y(value.x * -0.25)
