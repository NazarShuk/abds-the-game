extends Node3D

var penalties = 0
var previous_pos = Vector3.ZERO

@export var do_penalties = true
@export var debug = false
@export var max_penalties = 7
@export var required_distance = 1

var respawn_poses = []


func _ready():
	var poses = get_tree().get_nodes_in_group("respawn_pos")
	
	for pos in poses:
		respawn_poses.append(pos.global_position)

func _on_timer_timeout():
	if !multiplayer.is_server(): return
	if !Game.game_started: return
	if !do_penalties: return
	
	var diff = get_parent().global_position.distance_to(previous_pos)
	if debug:
		print_rich("[b]Penalties for ",get_parent().name, ": [/b]",penalties, "; Diff: ", diff)
	
	if diff > 1:
		penalties = 0
	else:
		penalties += 1
	
	if penalties >= max_penalties:
		
		var closest_dst = INF
		var closest_pos = Vector3.ZERO
		
		for pos in respawn_poses:
			var dst = global_position.distance_to(pos)
			if dst < closest_dst:
				closest_dst = dst
				closest_pos = pos
		
		get_parent().global_position = closest_pos
		penalties = 0
	
	previous_pos = get_parent().global_position
