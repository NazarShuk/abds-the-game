extends TextureRect

@export var is_shown : bool = false

func _process(_delta):
	if is_shown:
		position.x = lerp(position.x,687.0,0.05)
	else:
		position.x = lerp(position.x,1500.0,0.05)
