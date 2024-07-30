extends Node3D


func play():
	$SubViewport/VideoStreamPlayer.play()
	$AudioStreamPlayer3D.play()

func stop():
	$SubViewport/VideoStreamPlayer.stop()
	$AudioStreamPlayer3D.stop()
