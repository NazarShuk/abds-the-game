extends Node2D

@onready var music_slider = $CanvasLayer/MusicSlider
@onready var sfx_slider = $CanvasLayer/SfxSlider
var cangoof = false

func _ready():
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))



func _on_music_slider_changed(value):
	AudioServer.set_bus_volume_db(1,linear_to_db(value))
	
	
	AudioVolume.music_vol = linear_to_db(value)
	AudioVolume.save_values()

func _on_sfx_slider_changed(value):
	AudioServer.set_bus_volume_db(2,linear_to_db(value))
	AudioServer.set_bus_volume_db(3,linear_to_db(value))
	
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
