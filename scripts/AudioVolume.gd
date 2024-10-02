extends Node

const FILE_PATH = "user://settings.save"

var music_vol
var sfx_vol
var mic_threshold
var voice_chat_vol
var input_device

var better_lighting
var resolution_scale
var render_distance

func save_values():
	var game_save = FileAccess.open(FILE_PATH,FileAccess.WRITE)
	
	game_save.store_var(music_vol)
	game_save.store_var(sfx_vol)
	game_save.store_var(mic_threshold)
	game_save.store_var(voice_chat_vol)
	game_save.store_var(input_device)
	game_save.store_var(better_lighting)
	game_save.store_var(resolution_scale)
	game_save.store_var(render_distance)
	game_save.close()
	

func load_values_and_apply():
	if FileAccess.file_exists(FILE_PATH):
		var game_save = FileAccess.open(FILE_PATH,FileAccess.READ)
		
		music_vol = game_save.get_var()
		sfx_vol = game_save.get_var()
		mic_threshold = game_save.get_var()
		voice_chat_vol = game_save.get_var()
		input_device = game_save.get_var()
		better_lighting = game_save.get_var()
		resolution_scale = game_save.get_var()
		render_distance = game_save.get_var()
		
		if music_vol:
			AudioServer.set_bus_volume_db(1,music_vol)
			AudioServer.set_bus_volume_db(3,music_vol)
		
		if sfx_vol:
			AudioServer.set_bus_volume_db(2,sfx_vol)
		
		if voice_chat_vol:
			AudioServer.set_bus_volume_db(7,voice_chat_vol)
		if input_device:
			AudioServer.input_device = input_device
		else:
			input_device = "Default"
			AudioServer.input_device = "Default"
		
		if resolution_scale:
			get_viewport().scaling_3d_scale = resolution_scale
		
		game_save.close()
