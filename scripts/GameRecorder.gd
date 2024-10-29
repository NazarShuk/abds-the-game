extends Node

var time = 0

var playback_time = 0

var recorded = {}
var playbacks : Array
var do_playback = false
@onready var camera_3d = $"../CanvasLayer/MultiPlayer/ColorRect/SubViewportContainer/SubViewport/Camera3D"
@onready var camera_3d_2 = $"../CanvasLayer/MultiPlayer/ColorRect/SubViewportContainer/SubViewport/Camera3D/Camera3D2"

func _ready():
	playbacks = GlobalVars.playbacks
	if playbacks != []:
		do_playback = true
		var players = []
		for frame in recorded:
			for pl in recorded[frame]:
				if !players.has(pl.name):
					players.append(pl.name)
		
		for pl in players:
			var player : CharacterBody3D = load("res://player_fake.tscn").instantiate()
			player.add_to_group("fake player trust")
			player.name =  pl
			get_parent().add_child(player)

func _process(delta):
	if get_tree().get_first_node_in_group("fake player trust"):
		camera_3d.global_position = lerp(camera_3d.global_position,get_tree().get_first_node_in_group("fake player trust").global_position,0.05)
		camera_3d.global_rotation = lerp(camera_3d.global_rotation,camera_3d_2.global_rotation,0.05)
		camera_3d_2.look_at(get_tree().get_first_node_in_group("fake player trust").global_position)
func _on_timer_timeout():
	for i in range(0,1):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			time += 1
			recorded[str(time)] = []
			for player : CharacterBody3D in players:
				recorded[str(time)].append({
					"name":player.name,
					"global_position":player.global_position,
					"global_rotation":player.global_rotation
				})
		
		
		var existing_pl = get_tree().get_nodes_in_group("fake player")
		for fake_pl in existing_pl:
			fake_pl.queue_free()
		
		if get_tree().get_first_node_in_group("player"): return
		playback_time += 1
		for playback in playbacks:
			if do_playback:
				if playback.has(str(playback_time)):
					var current_frame = playback[str(playback_time)]
					for pl in current_frame:
						get_node(NodePath(pl.name)).global_position = pl.global_position
						get_node(NodePath(pl.name)).global_rotation = pl.global_rotation
	
	


func _exit_tree():
	GlobalVars.playbacks = [recorded]
