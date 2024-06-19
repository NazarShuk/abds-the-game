@tool
extends Node3D

func _ready():
	if Engine.is_editor_hint():

		for child in $"Navigation/StaticBody3D/not floor".get_children():
			child.visible = false
		$Navigation/StaticBody3D/MeshInstance3D2.visible = false
	if not Engine.is_editor_hint():

		$Navigation/StaticBody3D/MeshInstance3D2.visible = true
		
		for child in $"Navigation/StaticBody3D/not floor".get_children():
			child.visible = true
