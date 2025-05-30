extends RigidBody3D

@export var item = -1
@export var is_expired = false

@export var pos : Vector3
@export var rot : Vector3

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		pos = global_position
		rot = global_rotation
	else:
		global_position = lerp(global_position, pos, delta * 25)
		global_rotation.x = lerp_angle(global_rotation.x, rot.x, delta * 25)
		global_rotation.y = lerp_angle(global_rotation.y, rot.y, delta * 25)
		global_rotation.z = lerp_angle(global_rotation.z, rot.z, delta * 25)  

func _on_timer_timeout():
	if multiplayer.is_server():
		is_expired = true
		print("expired")
		add_to_group("expired_item")

@rpc("any_peer","call_local")
func push_item(push_direction,push_force):
	if multiplayer.is_server():
		apply_central_impulse(-push_direction * push_force)

@rpc("any_peer","call_local")
func remove_item():
	if multiplayer.is_server():
		queue_free()
