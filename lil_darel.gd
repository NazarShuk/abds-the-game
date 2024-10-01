extends CharacterBody3D

var SPEED = 10

@onready var nav_agent = $NavigationAgent3D

@onready var evil_darel = get_tree().get_first_node_in_group("evil darel")

var inverse = false
var is_stopped = false

func _physics_process(delta):
	
	var target = get_tree().get_first_node_in_group("player").global_position
	
	if !inverse:
		if global_position.distance_to(target) > 5:
			look_at(target)
	
	if !is_stopped:
		if !inverse:
			translate(Vector3(0,0,-SPEED * delta))
		else:
			translate(Vector3(0,0,SPEED * delta))
	
	if global_position.distance_to(target) < 2:
		evil_darel.health += 0.01



func _on_timer_timeout():
	queue_free()

var did_touch_big_darel = false

func _on_area_3d_area_entered(area):
	if area.name == "big darel":
		if !did_touch_big_darel:
			did_touch_big_darel = true
			return
		
		area.get_parent().health -= 5
		queue_free()
	
