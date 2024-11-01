extends Area3D

@export var game : Node3D

func _process(delta: float) -> void:
	visible = game.can_escape

func _on_area_entered(area: Area3D) -> void:
	if multiplayer.is_server():
		if area.is_in_group("player_area"):
			if game.can_escape:
				game.ending_check()
