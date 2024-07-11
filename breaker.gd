extends StaticBody3D
@onready var light = $OmniLight3D

@export var game : Node3D
@export var yellow_light : Color
@export var red_light : Color


func _process(delta):
	light.light_energy = randf_range(0.8,1.2)
	if game.is_powered_off:
		light.light_color = red_light
	else:
		light.light_color = yellow_light
		light.visible = true


func _on_timer_timeout():
	if game.is_powered_off:
		light.visible = !light.visible

func audio(play_or_nah):
	if play_or_nah:
		$AudioStreamPlayer3D.play()
	else:
		$AudioStreamPlayer3D.stop()
