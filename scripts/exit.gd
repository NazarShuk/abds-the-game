extends Area3D

@export var game : Node3D

func _process(delta: float) -> void:
	visible = game.can_escape

func _on_area_entered(area: Area3D) -> void:
	if multiplayer.is_server():
		if area.is_in_group("player_area"):
			if game.can_escape:
				
				var player = area.get_parent()
				player.die.rpc_id(player.name.to_int(),"exit",false)
				Game.players[player.name.to_int()].escaped = true
				Game.info_text(player.steam_name + " escaped!")
				var escaped_players = 0
				for i in Game.players.keys():
					if Game.players[i].escaped or Game.players[i].is_dead:
						escaped_players += 1
				
				if escaped_players == Game.players.keys().size():
					game.ending_check()
