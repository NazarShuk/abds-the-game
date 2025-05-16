extends Node3D

@export var videos : Array[ProjectorVideo]
@onready var audio_player : AudioStreamPlayer = get_tree().get_first_node_in_group("main_music")

@onready var initial_clip = audio_player.stream
@onready var game : Node3D = get_tree().get_first_node_in_group("game")

var time_left = 100
var is_playing = false

@rpc("any_peer","call_local")
func play():
	if multiplayer.is_server() and !game.escape:
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
		if !game.escape:
			audio_player.play()
		$SubViewport/VideoStreamPlayer.stop()
