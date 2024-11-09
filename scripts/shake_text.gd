extends Label

var do_shake = false
@export var shake_strength = 5


func _process(delta: float) -> void:
	if do_shake:
		position = Vector2.ZERO + Vector2(randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength))
