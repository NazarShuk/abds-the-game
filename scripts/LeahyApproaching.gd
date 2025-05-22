extends TextureRect

@export var is_shown : bool = false
@export var distance = -1

var initial_x

func _ready():
	initial_x = position.x

func _process(delta):
	if is_shown:
		position.x = lerp(position.x,initial_x, delta * 5)
		$Label.text = str(floori(distance))
	else:
		position.x = lerp(position.x,-500.0, delta * 5)
