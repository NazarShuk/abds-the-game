extends TextureRect

@export var is_shown : bool = false

var initial_x

func _ready():
	initial_x = position.x

func _process(_delta):
	if is_shown:
		position.x = lerp(position.x,initial_x,0.1)
	else:
		position.x = lerp(position.x,-500.0,0.1)
