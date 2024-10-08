extends Node3D

@rpc("any_peer","call_local")
func play():
	$SubViewport/VideoStreamPlayer.play()
	$AudioStreamPlayer3D.play()

@rpc("any_peer","call_local")
func stop():
	$SubViewport/VideoStreamPlayer.stop()
	$AudioStreamPlayer3D.stop()
