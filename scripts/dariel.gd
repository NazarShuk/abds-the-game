extends CharacterBody3D


var speed = 7.0
var stunned = false

var time = 0.0

@export var player : BossfightPlayer
var player_path : Array[Vector3] = []
var _previous_player_pos = Vector3.ZERO
var chase = false

var times_hit = 0

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("clorox_bossfight"):
		if !stunned:
			stunned = true
			$Stunned.start()
			area.queue_free()
			
			$scream.play(0.3)
			
			speed += 0.5
			
			times_hit += 1

func _process(delta: float) -> void:
	time += delta
	
	if stunned:
		if sin(time * 10) > 0.5:
			visible = false
		else:
			visible = true
	else:
		visible = true
	
	if chase:
		if _previous_player_pos.distance_to(player.global_position) > 0.1:
			player_path.append(player.global_position)
			_previous_player_pos = player.global_position
		
		if player_path.size() > 0 and not stunned:
			look_at(player_path[0])
			global_position = global_position.move_toward(player_path[0], delta * speed * (global_position.distance_to(player.global_position) / 5))
			
			
			if global_position.distance_to(player_path[0]) < 1:
				player_path.remove_at(0)


func _on_stunned_timeout() -> void:
	stunned = false
