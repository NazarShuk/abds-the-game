extends Camera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
	
	if evil_leahy:
		global_position = evil_leahy.global_position + Vector3(0,7,0)
		global_rotation_degrees.x = -90
		set_orthogonal(15,0.001,1000)
