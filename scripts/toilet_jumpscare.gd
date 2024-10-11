extends ColorRect


func _on_visibility_changed():
	if visible:
		$AnimationPlayer.play("jumpscare")
