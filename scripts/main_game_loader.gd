extends Control

const main_game_path = "res://game.tscn"

var target_value = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ResourceLoader.load_threaded_request(main_game_path)

func _process(delta: float) -> void:
	var progress = []
	
	ResourceLoader.load_threaded_get_status(main_game_path,progress)
	
	if progress[0] > 0.1:
		target_value = progress[0]
	
	$CanvasLayer/ProgressBar.value = lerp($CanvasLayer/ProgressBar.value,target_value, delta * 3)
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(main_game_path)
		await Game.sleep(0.5)
		get_tree().change_scene_to_packed.call_deferred(packed_scene)
