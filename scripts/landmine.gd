extends Area3D


func _on_area_entered(area):
	if !multiplayer.is_server(): return
	
	if area.is_in_group("player_area") and Game.game_started:
		var player = area.get_parent()
		
		Game.info_text(player.steam_name + " slipped")
		var spawnpoint = get_tree().get_nodes_in_group("landmine_spawn").pick_random().global_position
		spawnpoint.y = 0.143
		global_position = spawnpoint
