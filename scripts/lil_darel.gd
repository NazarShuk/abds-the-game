extends CharacterBody3D

var SPEED = 10

@onready var nav_agent = $NavigationAgent3D

@onready var evil_darel = get_tree().get_first_node_in_group("evil darel")

var inverse = false
var is_stopped = false

func _ready():
	if Allsingleton.did_show_parry_tip == false:
		GuiManager.show_tip("[color=green]Parrying[/color]\nWhen a Darel head is close to you, [b]press F[/b] while looking at it to deflect it back at [color=yeloow]Darel.png[/color]", 7)
		Allsingleton.did_show_parry_tip = true

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
		
		if evil_darel.is_phase_2 == false:
			area.get_parent().health -= 5
		else:
			area.get_parent().health -= 1
		queue_free()
	
