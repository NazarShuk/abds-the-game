extends Node2D

@onready var music_slider = $CanvasLayer/MusicSlider
@onready var sfx_slider = $CanvasLayer/SfxSlider
@onready var mic_vol = $CanvasLayer/mic_vol

var cangoof = false



func _ready():
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))
	
	
	if Settings.better_lighting != null:
		$CanvasLayer/BetterLightingToggle.button_pressed = Settings.better_lighting
	
	if Settings.resolution_scale != null:
		$CanvasLayer/InGameResolutionSlider.value = Settings.resolution_scale
	
	if Settings.render_distance != null:
		$CanvasLayer/RenderDistanceSlider.value = Settings.render_distance



func _on_music_slider_changed(value):
	AudioServer.set_bus_volume_db(1,linear_to_db(value))
	
	
	Settings.music_vol = linear_to_db(value)
	Settings.save_values()

func _on_sfx_slider_changed(value):
	AudioServer.set_bus_volume_db(2,linear_to_db(value))
	
	Settings.sfx_vol = linear_to_db(value)
	Settings.save_values()
	
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


func _on_better_lighting_toggle_toggled(toggled_on):
	Settings.better_lighting = toggled_on
	Settings.save_values()


func _on_in_game_resolution_slider_value_changed(value):
	Settings.resolution_scale = value
	Settings.save_values()


func _on_render_distance_slider_value_changed(value):
	Settings.render_distance = value
	Settings.save_values()
