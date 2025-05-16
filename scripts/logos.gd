extends Node2D

const main_game_path = "res://game.tscn"

var accepted_the_thing = false

func _ready():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	
	Settings.load_values_and_apply()
	Game.reset_values()
	
	AudioServer.set_bus_solo(6,false)

	GuiManager.force_cursor_state(true)
	
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	GlobalVars.menu_music_duration = 0
	
	GlobalVars.is_steam_peer = false
	
	if GlobalVars.firstTime:
		$AnimationPlayer.play("animat")
	
	if not GlobalVars.game_scene:
		ResourceLoader.load_threaded_request(main_game_path)
		var loading = true
		
		while loading:
			await Game.sleep(0.01)
			var progress = []
			
			ResourceLoader.load_threaded_get_status(main_game_path,progress)
			
			if progress[0] == 1:
				GlobalVars.game_scene = ResourceLoader.load_threaded_get(main_game_path)
				loading = false
	
	await Game.sleep(0.5)
	
	if GlobalVars.firstTime:
		$CanvasLayer/Warning.show()
		$CanvasLayer/Warning/meat.play()		
		while accepted_the_thing == false:
			await get_tree().create_timer(0.01).timeout
		
		$CanvasLayer/Warning/bam.play()
		$CanvasLayer/Warning/meat.stop()
		$CanvasLayer/Label.hide()
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property($CanvasLayer/Warning, "modulate", Color.TRANSPARENT, 0.25)
		
		await get_tree().create_timer(1, false).timeout
	
	GuiManager.reset_cursor()
	
	
	GlobalVars.firstTime = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")


func _on_button_pressed() -> void:
	accepted_the_thing = true
