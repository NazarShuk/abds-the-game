extends StaticBody3D
@onready var light = $OmniLight3D

@export var yellow_light : Color
@export var red_light : Color
@onready var audio = $AudioStreamPlayer3D
@onready var power_outage = $power_outage

func _ready():
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("breaker"):
		queue_free()

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


@rpc("any_peer","call_local")
func toggle_power(do_ov = false, ov = false):
	if !multiplayer.is_server(): return
	
	if !do_ov:
		Game.set_powered_off.rpc(!Game.powered_off)
	else:
		Game.set_powered_off.rpc(ov)
	
	if !Game.powered_off:
		turn_power_on.rpc()
		Game.set_powered_off.rpc(false)
	else:
		turn_power_off.rpc()
		Game.set_powered_off.rpc(true)

@rpc("authority","call_local")
func turn_power_on():
	Game.environment.background_energy_multiplier = 1
	Game.sun.light_energy = 1
	audio.play()
	power_outage.stop()

@rpc("authority","call_local")
func turn_power_off():
	Game.environment.background_energy_multiplier = 0
	Game.sun.light_energy = 0
	audio.stop()
	power_outage.play()
