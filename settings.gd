extends Node2D

@onready var music_slider = $CanvasLayer/MusicSlider
@onready var sfx_slider = $CanvasLayer/SfxSlider
@onready var mic_vol = $CanvasLayer/mic_vol

var cangoof = false

@onready var effect : AudioEffectCapture = AudioServer.get_bus_effect(5,4)
@onready var threshold_slider = $CanvasLayer/mic_vol/threshold_slider
var hear_urself = false
@onready var mic_list = $CanvasLayer/MicList


func _ready():
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))
	
	
	if AudioVolume.mic_threshold:
		threshold_slider.value = AudioVolume.mic_threshold
	else:
		AudioVolume.mic_threshold = threshold_slider.value
		AudioVolume.save_values()
	
	var mics = AudioServer.get_input_device_list()
	
	
	for mic in mics:
		mic_list.add_item(mic)
	
	if AudioVolume.input_device:
		print("selected")
		mic_list.select(mics.find(AudioVolume.input_device),true)
	
	

func _exit_tree():
	AudioServer.set_bus_mute(4,true)
	pass

func _process(delta):
	var stereoData : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	if stereoData.size() > 0:
		var data = PackedFloat32Array()
		data.resize(stereoData.size())
		var maxAmplitude := 0.0
		
		for i in range(stereoData.size()):
			var value = (stereoData[i].x + stereoData[i].y) / 2
			maxAmplitude = max(value,maxAmplitude)
			data[i] = value
		#print(maxAmplitude)
		mic_vol.value = lerp(mic_vol.value,maxAmplitude,0.25)
		
		var bg : StyleBoxFlat = StyleBoxFlat.new()
		if maxAmplitude > threshold_slider.value:
			bg.bg_color = Color.GREEN
			if hear_urself:
				AudioServer.set_bus_mute(4,false)
		else:
			bg.bg_color = Color.GRAY
			AudioServer.set_bus_mute(4,true)
		$CanvasLayer/mic_vol.set("theme_override_styles/background",bg)


func _on_music_slider_changed(value):
	AudioServer.set_bus_volume_db(1,linear_to_db(value))
	
	
	AudioVolume.music_vol = linear_to_db(value)
	AudioVolume.save_values()

func _on_sfx_slider_changed(value):
	AudioServer.set_bus_volume_db(2,linear_to_db(value))
	
	AudioVolume.sfx_vol = linear_to_db(value)
	AudioVolume.save_values()
	
	if cangoof:
		var audio = AudioStreamPlayer.new()
		audio.stream = load("res://goofball.mp3")
		audio.bus = "Dialogs"
		add_child(audio)
		audio.play(0.19)
		cangoof = false

func _on_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")

func _on_goofball_timer_timeout():
	cangoof = true


func _on_button_2_pressed():
		get_tree().change_scene_to_file("res://noescape.tscn")

func _on_threshold_slider_value_changed(value):
	AudioVolume.mic_threshold = value
	AudioVolume.save_values()


func _on_check_button_toggled(toggled_on):
	hear_urself = toggled_on


func _on_v_cslider_value_changed(value):
	AudioVolume.voice_chat_vol = value
	AudioVolume.save_values()
	AudioServer.set_bus_volume_db(7,linear_to_db(value))


func _on_mic_list_item_selected(index):
	var dev = mic_list.get_item_text(index)
	AudioServer.input_device = dev
	AudioVolume.input_device = dev
	AudioVolume.save_values()
