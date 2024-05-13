extends TextureRect

@export var is_shown : bool = false

func _process(delta):
	if is_shown:
		position.x = lerp(position.x,687.0,0.25)
	else:
		position.x = lerp(position.x,1500.0,0.25)
