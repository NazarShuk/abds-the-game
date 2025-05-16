extends ColorRect


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")
