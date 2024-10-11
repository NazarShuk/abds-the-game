extends Control

var dialog_stream = []
@onready var http = $HTTPRequest
var audio_player : AudioStreamPlayer

var prompt_idx = 0

var target_bg_color = Color.WHITE
var target_bg_pitch = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	AudioServer.set_bus_solo(6,false)
	
	
	var body = JSON.stringify({
		"text":get_the_prompt(prompt_idx),
		"voice":"en_us_006",
		"base64":true
	})
	
	http.request("https://tiktok-tts.weilbyte.dev/api/generate",["Content-Type: application/json"],HTTPClient.METHOD_POST,body)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if audio_player:
		var capture : AudioEffectCapture = AudioServer.get_bus_effect(2,0)
		var buff : PackedVector2Array = capture.get_buffer(capture.get_frames_available())
		
		var data = PackedFloat32Array()
		data.resize(buff.size())
		var maxAmplitude := 0.0
		
		for i in range(buff.size()):
			var value = (buff[i].x + buff[i].y) / 2
			maxAmplitude = max(value,maxAmplitude)
			data[i] = value
		
		$AzzuHandle/TextureRect.scale.x = 1 - (maxAmplitude / 5)
		$AzzuHandle/TextureRect.scale.y = 1 + (maxAmplitude / 5)
	
	$ColorRect.color = lerp($ColorRect.color,target_bg_color,0.01)
	$bg.pitch_scale = lerp($bg.pitch_scale,float(target_bg_pitch),0.005)
	

func _on_http_request_request_completed(result, response_code, headers, body):
	
	if result == OK:
		var base_64_str = body.get_string_from_utf8()
		var decoded_audio = Marshalls.base64_to_raw(base_64_str)
		
		var file = FileAccess.open("user://dumb_dialog.mp3",FileAccess.WRITE)
		file.store_buffer(decoded_audio)
		file.close()
		
		var stream = AudioStreamMP3.new()
		stream.data =  FileAccess.get_file_as_bytes("user://dumb_dialog.mp3")
		
		dialog_stream.append(stream)
		prompt_idx += 1
		if prompt_idx < 4:
			var coolBody = JSON.stringify({
			"text":get_the_prompt(prompt_idx),
			"voice":"en_us_006",
			"base64":true
			})
			
			http.request("https://tiktok-tts.weilbyte.dev/api/generate",["Content-Type: application/json"],HTTPClient.METHOD_POST,coolBody)
		else:
			prompt_idx = 0
			$AnimationPlayer.play("main")
			await Game.sleep(2)
			play_da_dialog()
	else:
		print("idk error ",result)
		$AnimationPlayer.play("main")
		await Game.sleep(2)
		
		var audio = AudioStreamPlayer.new()
		audio.stream = load("res://18001818_uhm._there_was_s.mp3")
		add_child(audio)
		audio.play()
		audio.bus = "Dialogs"
		await Game.sleep(10)
		get_tree().change_scene_to_file("res://game.tscn")
		

func play_da_dialog():
	if prompt_idx == 3:
		await Game.sleep(5)
	if prompt_idx < 4:
		var audio : AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(audio)
		audio.stream = dialog_stream[0]
		
		if prompt_idx == 1:
			target_bg_color = Color.GRAY
			target_bg_pitch = 0.9
		elif prompt_idx == 2:
			target_bg_color = Color.BLACK
			audio.pitch_scale = 0.85
			target_bg_pitch = 0.5
		elif prompt_idx == 3:
			target_bg_color = Color.WHITE
			$bg.pitch_scale = 1
			$ColorRect.color = Color.WHITE
			audio.pitch_scale = 1
			target_bg_pitch = 1
		
		
		audio.play()
		prompt_idx += 1
		audio_player = audio
		audio.bus = "Dialogs"
		
		dialog_stream.remove_at(0)
		await Game.sleep(audio.stream.get_length())
		if prompt_idx == 4:
			await Game.sleep(2)
			get_tree().change_scene_to_file("res://game.tscn")
		else:
			play_da_dialog()


func get_the_prompt(which_one):
	
	var fake_name = "Player"
	if !Allsingleton.non_steam:
		fake_name = Steam.getPersonaName()
	
	var user_dir = OS.get_user_data_dir()
	
	var extracted_name = user_dir.split("/AppData")[0].split("/Users/")[1]
	print(extracted_name)
	print(fake_name)
	
	if which_one == 0:
		var pre_formatted_prompt = "Hey there goofball. Im like confused. How dumb can you be, to not even collect the first notebook, and DIE TEN FRICKING TIMES?"
		var formatted_prompt = pre_formatted_prompt
	
		return formatted_prompt
	elif which_one == 1:
		var pre_formatted_prompt = "I think you are tricking me. Your name is not %s."
		var formatted_prompt = pre_formatted_prompt  % [fake_name]
		return formatted_prompt
	elif which_one == 2:
		var pre_formatted_prompt = " I know it isn't, because your real name, is actually, %s"
		var formatted_prompt = pre_formatted_prompt  % [extracted_name]
		return formatted_prompt
	elif which_one == 3:
		var pre_formatted_prompt = "Anyways, bye bye, %s"
		var formatted_prompt = pre_formatted_prompt  % [extracted_name]
		return formatted_prompt
	
