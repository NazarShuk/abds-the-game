extends ColorRect

@export var speed : float = 10

func _process(delta):
	color = color.lerp(Color(255,255,255,0),speed * delta)

func flash():
	color = Color.WHITE
