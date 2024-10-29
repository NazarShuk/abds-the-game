extends Node3D

@export var camera : Camera3D

func _ready() -> void:
	camera.global_position = global_position
