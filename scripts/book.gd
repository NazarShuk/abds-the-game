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
		
		if not Game.competitive:
			Game.info_text(player.steam_name + " collected a notebook!")
		else:
			
			var total_books = 0
			for idx in Game.players:
				if Game.players[idx].team == Game.players[id].team:
					total_books += Game.players[id].books_collected
			
			var notebook_text = str(total_books)
			
			if total_books == 1:
				notebook_text += "st"
			elif total_books == 2:
				notebook_text += "nd"
			elif total_books == 3:
				notebook_text += "rd"
			else:
				notebook_text += "th"
			
			Game.info_text("Team " + Game.players[id].team + " collected their " + notebook_text + " notebook!")
		
		global_position = get_tree().get_nodes_in_group("book_spawn").pick_random().global_position
