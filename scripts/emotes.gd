extends Node3D

@export var player : Player

const emotes = {
	"dance": {
		"video": preload("res://video/soup_dance.ogv"),
		"audio": preload("res://video/soup_dance.mp3")
	}
}

var emoting = false

func _ready() -> void:
	if is_multiplayer_authority() == false:
		$CanvasLayer/SubViewportContainer/SubViewport/Camera3D.queue_free()

func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("back") or Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
		if emoting:
			stop_emoting_local()
	
	if Input.is_action_just_pressed("emote"):
		start_emoting_local("dance")
	
	if emoting:
		$CanvasLayer/SubViewportContainer/SubViewport/Camera3D.global_transform = $camera_target.global_transform

func start_emoting_local(emote: String):
	AudioServer.set_bus_solo(8, true)
	emoting = true
	$CanvasLayer.show()
	
	start_emote.rpc(emote, $SubViewport/CanvasLayer/video.get_path(), $audio.get_path(), self.get_path())
	$Timer.start(emotes[emote].audio.get_length())

@rpc("authority", "call_local")
func start_emote(emote : String, video_path : String, audio_path: String, emote_path: String):
	var video = get_node_or_null(video_path)
	if !video: return
	var audio = get_node_or_null(audio_path)
	if !audio: return
	var emote_node = get_node_or_null(emote_path)
	if !emote_node: return
	
	video.stream = emotes[emote].video
	audio.stream = emotes[emote].audio
	
	audio.play()
	video.play()
	
	emote_node.show()

func stop_emoting_local():
	stop_emoting.rpc($SubViewport/CanvasLayer/video.get_path(), $audio.get_path(), self.get_path())
	AudioServer.set_bus_solo(8, false)
	$CanvasLayer.hide()
	$Timer.stop()
	print("stopping emote")
	emoting = false

@rpc("authority", "call_local")
func stop_emoting(video_path : String, audio_path: String, emote_path: String):
	var video = get_node_or_null(video_path)
	if !video: return
	var audio = get_node_or_null(audio_path)
	if !audio: return
	var emote_node = get_node_or_null(emote_path)
	if !emote_node: return
	
	emote_node.hide()
	audio.stop()
	video.stop()


func _exit_tree() -> void:
	AudioServer.set_bus_solo(8, false)


func _on_timer_timeout() -> void:
	if emoting:
		stop_emoting_local()
