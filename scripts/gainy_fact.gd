extends ColorRect

@export var player : Player

var time = 0
var scale_transition = 0.0

@onready var camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D

func _ready() -> void:
	pivot_offset = size / 2

func _process(delta: float) -> void:
	
	
	scale.x = (1 + sin(time) * 0.25) * scale_transition
	scale.y = (1 + cos(time) * 0.25) * scale_transition
	
	rotation = sin(time) * 0.25
	
	var gainy = get_tree().get_first_node_in_group("ms_gainy")
	
	if gainy:
		time += delta * 5
		
		if gainy.target_player && gainy.target_player_name == player.steam_name:
			scale_transition = lerp(scale_transition, 1.0, delta * 10)
		else:
			scale_transition = lerp(scale_transition, 0.0, delta * 10)
		
		camera.global_position.x = lerp(camera.global_position.x, gainy.global_position.x, delta * 25)
		camera.global_position.z = lerp(camera.global_position.z, gainy.global_position.z, delta * 25)
		
	else:
		scale_transition = lerp(scale_transition, 0.0, delta * 10)
