extends AudioStreamPlayer3D

@export_range(0,4) var range : float

func _ready() -> void:
	pitch_scale = 1 + randf_range(-range,range)
