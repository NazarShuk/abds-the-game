extends Node3D

signal player_entered(player: BossfightPlayer)

var did_enter = false

func _on_enter_body_entered(body: Node3D) -> void:
	if body is BossfightPlayer and not did_enter:
		player_entered.emit(body)
		did_enter = true
