extends Node

var time = 0

var recorded = {}
var playbacks : Array
var do_playback = false

func _ready():
	playbacks = Allsingleton.playbacks
	if playbacks != []:
		do_playback = true

func _on_timer_timeout():
	for i in range(0,1):
		time += 1
		recorded[str(time)] = []
		
		var players = get_tree().get_nodes_in_group("player")
		for player : CharacterBody3D in players:
			recorded[str(time)].append({
				"global_position":player.global_position,
				"global_rotation":player.global_rotation
			})
		
		
		var existing_pl = get_tree().get_nodes_in_group("fake player")
		for fake_pl in existing_pl:
			fake_pl.queue_free()
		
		if get_tree().get_first_node_in_group("player"): return
		for playback in playbacks:
			if do_playback:
				if playback.has(str(time)):
					var current_frame = playback[str(time)]
					for pl in current_frame:
						var player = load("res://player_fake.tscn").instantiate()
						
						get_parent().add_child(player)
						
						player.global_position = pl.global_position
						player.global_rotation = pl.global_rotation
	
	


func _exit_tree():
	Allsingleton.playbacks = [recorded]
