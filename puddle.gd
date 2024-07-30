extends Node3D

@export var can_slowdown = false

func _on_timer_timeout():
	if multiplayer.is_server():
		can_slowdown = true
