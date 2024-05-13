extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D


var SPEED = 10.0

func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * SPEED	
	
	velocity = new_velocity
	move_and_slide()

func update_target_location(target_location):
	nav_agent.target_position = target_location
	look_at(target_location)


func _on_timer_timeout():
	$AudioStreamPlayer3D.pitch_scale = randf_range(0.75,1.25)

func play_audio():
	$AudioStreamPlayer3D.play()
