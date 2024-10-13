extends Node2D



func _on_video_stream_player_finished():
	$Timer.start()


func _on_timer_timeout():
	get_tree().change_scene_to_file.call_deferred("res://logos.tscn")
