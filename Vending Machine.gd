extends StaticBody3D

@export var uses_left = 20

func _on_timer_timeout():
	if uses_left <= 0:
		$OmniLight3D.visible = !$OmniLight3D.visible
	else:
		$OmniLight3D.visible = false
