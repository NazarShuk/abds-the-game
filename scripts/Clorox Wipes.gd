extends StaticBody3D

var SPEED = 10
@export var initial_pos : Vector3
@export var launcher : int

var reversed = false
@export var is_evil = false

var auto_aim = false
var auto_aim_node
var auto_aim_did_capture = false
var auto_aim_capture_node

var stop_timer = false
var is_stopped = false


func _ready():
	global_position = initial_pos
	if !GlobalVars.is_bossfight:
		$Timer.start(3)
	else:
		if !stop_timer:
			$Timer.start(15)
	
	if is_evil:
		$hand.show()
		$wipe.hide()

func _process(delta):
	if !is_stopped:
		if !reversed:
			translate(Vector3(0,0,-SPEED * delta))
		else:
			translate(Vector3(0,0,SPEED * delta))
	
	if is_evil:
		var player = get_tree().get_first_node_in_group("player")
		if player.is_dead:
			queue_free()
		
		if global_position.distance_to(player.global_position) < 2:
			player.global_position = global_position
		
		$AudioStreamPlayer3D.pitch_scale = 3
	
	if auto_aim:
		var pos
		if auto_aim_did_capture:
			pos = auto_aim_node.global_position
			look_at(pos)
			if global_position.distance_to(pos) < 5:
				queue_free()
		else:
			pos = auto_aim_capture_node.global_position
			look_at(pos)
			if global_position.distance_to(pos) < 1:
				auto_aim_did_capture = true
		
	
func start_timer(sec):
	$Timer.start(sec)

func _on_timer_timeout():
	queue_free()
