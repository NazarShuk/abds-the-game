extends Camera3D

@export var target : Node3D
@export var speed : float

func _physics_process(delta: float) -> void:
	global_position = lerp(global_position, target.global_position, delta * speed)
	global_rotation = lerp(global_rotation, target.global_rotation, delta * speed)
