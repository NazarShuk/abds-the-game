extends Control

func _ready() -> void:
	if not OS.has_feature("debug"):
		queue_free()
