extends StaticBody3D

const SPEED = 10
@export var initial_pos : Vector3
@export var launcher : int

var reversed = false
@export var is_evil = false

var auto_aim = false
var auto_aim_node

func _ready():
	global_position = initial_pos
	if !Allsingleton.is_bossfight:
		$Timer.start(3)
	else:
		$Timer.start(15)

func _process(delta):
	if !reversed:
		translate(Vector3(0,0,-SPEED * delta))
	else:
		translate(Vector3(0,0,SPEED * delta))
	
	if is_evil:
		var player = get_tree().get_first_node_in_group("player")
		if player.is_dead:
			queue_free()
		player.global_position = global_position
		$AudioStreamPlayer3D.pitch_scale = 3
	
	if auto_aim:
		var pos = auto_aim_node.global_position
		look_at(pos)
		
		if global_position.distance_to(pos) < 5:
			queue_free()
		
	
func start_timer(sec):
	$Timer.start(sec)

func _on_timer_timeout():
	queue_free()
