extends StaticBody3D

const MAX_USES = 20

@export var uses_left = MAX_USES
@export var override_drops = false
@export var overriden_drops = {}

func _on_timer_timeout():
	if uses_left <= 0:
		$OmniLight3D.visible = !$OmniLight3D.visible
	else:
		$OmniLight3D.visible = false
