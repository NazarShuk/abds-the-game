extends Node3D

@export var videos : Array[ProjectorVideo]
@export var audio_player : AudioStreamPlayer

@onready var initial_clip = audio_player.stream

var time_left = 100
var is_playing = false

@rpc("any_peer","call_local")
func play():
	if multiplayer.is_server():
		set_video.rpc(randi_range(0,videos.size() - 1))


@rpc("authority","call_local")
func set_video(idx):
	var video = videos[idx]
	$SubViewport/VideoStreamPlayer.stream = video.video_file
	$SubViewport/VideoStreamPlayer.play()
	
	audio_player.stream = video.audio_file
	audio_player.play()
	
	time_left = video.audio_file.get_length()
	is_playing = true

func _process(delta: float) -> void:
	if time_left > 0 and is_playing:
		time_left -= delta * audio_player.pitch_scale
	elif is_playing:
		is_playing = false
		audio_player.stream = initial_clip
		audio_player.play()
		$SubViewport/VideoStreamPlayer.stop()
