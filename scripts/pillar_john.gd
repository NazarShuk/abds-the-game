extends StaticBody3D

func _process(_delta: float) -> void:
	var player = Game.get_closest_node_in_group(global_position, "player")
	if player:
		look_at(player.global_position)
		global_rotation_degrees.x = 0
