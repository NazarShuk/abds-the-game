extends StaticBody3D

@rpc("any_peer","call_local")
func play_sound():
	$coffee.play()

func _ready():
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("coffee_machine"):
		queue_free()
