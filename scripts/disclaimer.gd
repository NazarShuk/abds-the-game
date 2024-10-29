extends ColorRect

func _ready() -> void:
	if GlobalVars.did_show_disclaimer:
		queue_free()
	else:
		GlobalVars.did_show_disclaimer = true

func _process(_delta: float) -> void:
	if Input.is_anything_pressed():
		queue_free()
