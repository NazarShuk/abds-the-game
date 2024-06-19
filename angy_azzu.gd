extends Node2D

@export var capture_mouse = false

func _process(delta):
	if capture_mouse:
		get_viewport().warp_mouse($CanvasLayer/TextureRect2.global_position + Vector2(80,78))

func end():
	get_tree().change_scene_to_file("res://game.tscn")
