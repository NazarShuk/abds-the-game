extends ColorRect

func _ready() -> void:
	if Allsingleton.did_show_disclaimer:
		queue_free()
	else:
		Allsingleton.did_show_disclaimer = true

func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		queue_free()
