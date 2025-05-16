extends CanvasLayer

@export var screenshot : ImageTexture

const PART2 = preload("res://scenes/bossfight_part2.tscn")

func _ready() -> void:
	var time_multiplier = 1
	
	$TextureRect.texture = screenshot
