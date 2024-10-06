extends StaticBody3D
@onready var light = $OmniLight3D

@export var yellow_light : Color
@export var red_light : Color

func _process(_delta):
	light.light_energy = randf_range(0.8,1.2)
	if Game.powered_off:
		light.light_color = red_light
	else:
		light.light_color = yellow_light
		light.visible = true


func _on_timer_timeout():
	if Game.powered_off:
		light.visible = !light.visible

func audio(play_or_nah):
	if play_or_nah:
		$AudioStreamPlayer3D.play()
	else:
		$AudioStreamPlayer3D.stop()


@rpc("any_peer","call_local")
func toggle_power(do_ov = false, ov = false):
	
	if !do_ov:
		Game.set_param("powered_off",!Game.powered_off)
	else:
		Game.set_param("powered_off",ov)
	
	if !Game.powered_off:
		Game.environment.background_energy_multiplier = 1
		Game.sun.light_energy = 1
		
		$Music2.play()
		
		Game.info_text("Power was fixed")
		$Breaker.audio(true)
		$Breaker/AudioStreamPlayer.stop()
		$BreakerRoomClosedDoor.set_collision_layer_value(2,false)
		
		Game.set_param("powered_off", false)
	else:
		Game.environment.background_energy_multiplier = 0
		Game.sun.light_energy = 0
		$Music2.stop()
		
		Game.info_text("Power got broken")
		$Breaker.audio(false)
		$Breaker/AudioStreamPlayer.play()
		$BreakerRoomClosedDoor.set_collision_layer_value(2,true)
		
		Game.set_param("powered_off", true)
