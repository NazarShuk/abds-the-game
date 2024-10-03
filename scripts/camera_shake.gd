extends Camera3D

@export var do_shake = false
@export_range(0,15) var shake_strength : float

func _process(delta):
	if do_shake:
		h_offset = randf_range(-shake_strength,shake_strength)
		v_offset = randf_range(-shake_strength,shake_strength)
	else:
		h_offset = 0
		v_offset = 0
