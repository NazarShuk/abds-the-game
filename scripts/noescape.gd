extends Node2D

var initalPos = Vector2()
var initialSize

func _ready():
	OS.alert("intermission")
	initalPos = DisplayServer.window_get_position()
	initialSize = DisplayServer.window_get_size()

func _on_video_stream_player_finished():
	get_tree().change_scene_to_file.call_deferred("res://logos.tscn")
	
	
	
func _process(delta):
	var width = randi_range(0, 5)
	var height = randi_range(0, 5)

	width = width + initalPos.x
	height = height + initalPos.y
	
	var x = randi_range(0, 15) + initialSize.x
	var y = randi_range(0, 15) + initialSize.y
	
	get_window().position = Vector2(width,height)
	get_window().size = Vector2(x,y)
	get_window().mode = Window.MODE_WINDOWED
