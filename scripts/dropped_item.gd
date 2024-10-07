extends RigidBody3D

@export var item = -1
@export var is_expired = false

func _on_timer_timeout():
	if multiplayer.is_server():
		is_expired = true
		print("expired")
		add_to_group("expired_item")

@rpc("any_peer","call_local")
func push_item(push_direction,push_force):
	if multiplayer.is_server():
		apply_central_impulse(-push_direction * push_force)
