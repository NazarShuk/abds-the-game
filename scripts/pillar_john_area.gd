extends "res://scenes/music_disable_area.gd"

func _ready() -> void:
	var game = get_tree().get_first_node_in_group("game")
	if !game: return
	
	music = [
		game.get_node("Music0"),
		game.get_node("Music1"),
		game.get_node("Music2"),
	]
