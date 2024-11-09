extends Control

var do_shake = false
@export var shake_strength = 5
@onready var initial_position = position

func _process(delta: float) -> void:
	if do_shake:
		position = initial_position + Vector2(randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength))
