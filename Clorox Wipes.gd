extends StaticBody3D

const SPEED = 10
@export var initial_pos : Vector3
@export var launcher : int

func _ready():
	global_position = initial_pos
	if !Allsingleton.is_bossfight:
		$Timer.start(3)
	else:
		$Timer.start(15)

func _process(delta):
	translate(Vector3(0,0,-SPEED * delta))


func _on_timer_timeout():
	queue_free()
