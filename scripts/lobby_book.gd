extends TextureRect


func remove() -> void:
	var tween = create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "scale", Vector2(0, 0), 1)
	tween.tween_property(self, "rotation_degrees", -360 * 2, 1)
	await tween.finished
	
	queue_free()
