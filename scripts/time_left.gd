extends Label

@export var timer : Timer

func _process(delta: float) -> void:
	text = str(floor(timer.time_left))
