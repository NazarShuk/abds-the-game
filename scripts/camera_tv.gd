extends MeshInstance3D

@export var subviewports : Array[SubViewport]
var is_visible = true

func _process(_delta: float) -> void:
	var closest_player = Game.get_closest_node_in_group(global_position,"player")
	
	if closest_player:
		if global_position.distance_to(closest_player.global_position) < 10 and !is_visible:
			toggle_subviewports(true)
		else:
			toggle_subviewports(false)
	else:
		toggle_subviewports(false)

func toggle_subviewports(enable : bool):
	if enable:
		for subviewport in subviewports:
			subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	else:
		for subviewport in subviewports:
			subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	is_visible = enable
