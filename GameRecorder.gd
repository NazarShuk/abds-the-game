extends Node

@onready var game = $".."

var recorded=[]
@onready var evil_leahy = $"../EvilLeahy"

var is_recording = false

func _process(delta):
	if is_recording:
		var block = {
			"books_to_collected":game.books_to_collect,
			"total_books":game.total_books,
			"leahy":{
				"position":evil_leahy.global_position,
				"rotation":evil_leahy.global_rotation
			},
			"players":[]
		}
		
		var players = get_tree().get_nodes_in_group("player")
		
		for player in players:
			block.players.append({
				"name":player.steam_name,
				"position":player.global_position,
				"rotation":player.global_rotation,
			})
		recorded.append(block)
		print(block)
