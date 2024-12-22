extends "res://scripts/teacher.gd"
class_name EvilDarel

var health = 100

@export var bossfight : Bossfight

signal damaged

func _process(delta: float) -> void:
	if !bossfight.do_bossfight: return
	
	var player = Game.get_closest_node_in_group(global_position, "player")
	
	if player:
		target_player = player
		update_target_location(player.global_position)
	else:
		target_player = null
	
	
	if OS.has_feature("debug"):
		if Input.is_action_just_pressed("debug"):
			health -= 10
			damaged.emit()


func _on_darel_area_entered(area: Area3D) -> void:
	if area.is_in_group("clorox_bossfight"):
		area.queue_free()
		health -= 10
		speed_multiplier += 0.05
		damaged.emit()
		
		add_speed_multiplier(-speed_multiplier, 2)
		
		$scream.play()
		
		if health <= 0:
			bossfight.transition_to_phase_2()
			queue_free()
