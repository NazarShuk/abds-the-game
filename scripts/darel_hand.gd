extends Node3D


func pick_item(id = -1):
	for child in get_children():
			child.hide()
	
	if id != -1:
		get_child(id).show()
