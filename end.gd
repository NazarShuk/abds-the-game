extends Node3D


@export var died_text : Label
@export var collected_text : Label
@export var achievement_name : String

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	
	died_text.text = "you died " + str(EndGameSingleton.deaths) + " times"
	collected_text.text = "and collected " + str(EndGameSingleton.books_collected) + " notebooks"
	
	Achievements.set_val(achievement_name,true)

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://game.tscn")

func _input(event):
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("res://game.tscn")
