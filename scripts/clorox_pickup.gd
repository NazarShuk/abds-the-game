extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is BossfightPlayer:
		var player : BossfightPlayer = body
		player.has_clorox = true
		queue_free()
