extends MeshInstance3D

func _ready():
	Game.on_game_started.connect(_on_start_game)
	Game.on_pre_game_started.connect(on_pre_start_game)
	if GlobalVars.is_bossfight:
		queue_free()

func on_pre_start_game():
	if !Game.game_params.get_param("ms_leahy"):
		queue_free()

func _on_start_game():
	queue_free()
