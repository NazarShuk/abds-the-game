extends Camera3D

var initial_position : Vector3
var target_position : Vector3

func _ready() -> void:
	initial_position = global_position
	target_position = initial_position

func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, delta * 5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		target_position = initial_position + (Vector3(event.relative.x, event.relative.y, 0) / 200)
