extends Area3D

@export var music : Array[AudioStreamPlayer]

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_area"):
		var player = area.get_parent()
		if player.name.to_int() == multiplayer.get_unique_id():
			for m in music:
				m.volume_db = -80


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("player_area"):
		var player = area.get_parent()
		if player.name.to_int() == multiplayer.get_unique_id():
			for m in music:
				m.volume_db = 0
