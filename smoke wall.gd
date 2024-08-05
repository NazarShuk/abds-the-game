extends FogVolume


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(2).timeout
	$StaticBody3D/CollisionShape3D.disabled = false
	
	if multiplayer.is_server():
		await get_tree().create_timer(randi_range(30,75)).timeout
		queue_free()
