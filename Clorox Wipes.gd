extends StaticBody3D

const SPEED = 10
@export var initial_pos : Vector3

func _ready():
	global_position = initial_pos

func _process(delta):
	translate(Vector3(0,0,-SPEED * delta))


func _on_timer_timeout():
	queue_free()
