extends Area3D

const SLIPPING_ON_BANANA = preload("res://sounds/slipping-on-banana.mp3")

func _ready():
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("bananas"):
		queue_free()

func _on_area_entered(area):
	if !multiplayer.is_server(): return
	
	if area.is_in_group("player_area") and Game.game_started:
		var player = area.get_parent()
		
		play_skibidi_sound.rpc()
		
		var spawnpoint = get_tree().get_nodes_in_group("landmine_spawn").pick_random().global_position
		spawnpoint.y = 0.143
		global_position = spawnpoint

@rpc("authority","call_local")
func play_skibidi_sound():
	var aud = AudioStreamPlayer3D.new()
	aud.stream = SLIPPING_ON_BANANA
	aud.max_distance = 30
	aud.bus = "Dialogs"
	
	get_parent().add_child(aud)
	aud.play()
	aud.global_position = global_position
	
	await Game.sleep(aud.stream.get_length())
	aud.queue_free()
