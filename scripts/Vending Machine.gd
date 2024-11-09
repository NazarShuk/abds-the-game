extends StaticBody3D

const MAX_USES = 20

@export var uses_left = MAX_USES
@export var override_drops = false
@export var overriden_drops = {}

var shake = false
var shake_strength = 0.1
@onready var initial_pos = global_position

func _ready():
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("vending_machines"):
		queue_free()

func _on_timer_timeout():
	if uses_left <= 0:
		$OmniLight3D.visible = !$OmniLight3D.visible
		if $OmniLight3D.visible:
			$beep.play()
	else:
		$OmniLight3D.visible = false

func _process(delta: float) -> void:
	if shake:
		global_position = initial_pos + Vector3(randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength))
		
@rpc("any_peer","call_local")
func use_vending_machine():
	if multiplayer.is_server():
		uses_left -= 1
	
	shake = true
	await Game.sleep(0.1)
	shake = false
	global_position = initial_pos
	$AudioStreamPlayer.pitch_scale = randf_range(0.9,1.1)
	$AudioStreamPlayer.play()
