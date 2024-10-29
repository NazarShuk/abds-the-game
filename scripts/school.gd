@tool
extends Node3D

@export var debug_hide_ceiling = false

func _ready():
	if Engine.is_editor_hint() and debug_hide_ceiling:

		toggle_ceiling(false)
	else:
		toggle_ceiling(true)


func toggle_ceiling(do_show):
	if !do_show:
		for child in $"FloorSpecial/not floor".get_children():
			child.visible = false
	else:
		for child in $"FloorSpecial/not floor".get_children():
			child.visible = true
