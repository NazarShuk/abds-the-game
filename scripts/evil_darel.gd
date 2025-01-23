extends "res://scripts/teacher.gd"
class_name EvilDarel

var health = 100

@export var bossfight : Bossfight

signal damaged

var do_chase = true

func _process(delta: float) -> void:
	
	if OS.has_feature("debug"):
		if Input.is_action_just_pressed("debug") and not bossfight.phase_2:
			bossfight.transition_to_phase_2()

	
	if !bossfight.do_bossfight: return
	
	var player = Game.get_closest_node_in_group(global_position, "player")
	
	if player and do_chase:
		target_player = player
		update_target_location(player.global_position)
	else:
		target_player = null
		update_target_location(global_position)
	
	


func _on_darel_area_entered(area: Area3D) -> void:
	if area.is_in_group("clorox_bossfight"):
		area.queue_free()
		health -= area.damage
		speed_multiplier += 0.05
		damaged.emit()
		
		add_speed_multiplier(-speed_multiplier, 2)
		
		$scream.play()
		
		if health <= 0 and not bossfight.phase_2:
			bossfight.transition_to_phase_2()
