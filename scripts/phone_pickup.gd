extends StaticBody3D

@rpc("any_peer", "call_local")
func remove():
	queue_free()
