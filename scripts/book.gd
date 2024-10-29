extends StaticBody3D

func _on_book_area_entered(area):
	if !multiplayer.is_server(): return
	
	if area.is_in_group("player_area"):
		var player = area.get_parent()
		var id = player.name.to_int()
		
		Game.players[id].books_collected += 1 + Game.book_boost
		
		Game.calculate_total_books()
		
		Game.info_text(player.steam_name + " collected a book!")
		
		global_position = get_tree().get_nodes_in_group("book_spawn").pick_random().global_position
