extends StaticBody3D

@export var change_pos_on_game_start = false

func _ready() -> void:
	Game.on_game_started.connect(_on_game_started)

func _on_game_started():
	if change_pos_on_game_start:
		global_position = get_tree().get_nodes_in_group("book_spawn").pick_random().global_position

func _on_book_area_entered(area):
	if !multiplayer.is_server(): return
	
	if area.is_in_group("player_area"):
		var player = area.get_parent()
		var id = player.name.to_int()
		
		Game.players[id].books_collected += 1 + Game.book_boost
		
		Game.calculate_total_books()
		
		Game.info_text(player.steam_name + " collected a book!")
		
		global_position = get_tree().get_nodes_in_group("book_spawn").pick_random().global_position
