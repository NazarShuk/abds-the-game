extends StaticBody3D

const MAX_USES = 20

@export var uses_left = MAX_USES
@export var override_drops = false
@export var overriden_drops = {}

func _ready():
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("vending_machines"):
		queue_free()

func _on_timer_timeout():
	if uses_left <= 0:
		$OmniLight3D.visible = !$OmniLight3D.visible
	else:
		$OmniLight3D.visible = false

@rpc("any_peer","call_local")
func use_vending_machine():
	if multiplayer.is_server():
		uses_left -= 1
