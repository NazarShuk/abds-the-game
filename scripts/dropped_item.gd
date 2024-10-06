extends RigidBody3D

@export var item = -1
@export var is_expired = false

func _on_timer_timeout():
	if multiplayer.is_server():
		is_expired = true
		print("expired")
		add_to_group("expired_item")
