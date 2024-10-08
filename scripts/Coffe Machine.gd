extends StaticBody3D

@rpc("any_peer","call_local")
func play_sound():
	$coffee.play()
