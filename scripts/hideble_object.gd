@tool
extends Node3D

@export var node_to_hide : NodePath

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		get_node(node_to_hide).show()
	else:
		get_node(node_to_hide).hide()
