extends FogVolume

var navigation_mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer.is_server():
		await Game.sleep(10)
		navigation_mesh.bake_navigation_mesh()
		await Game.sleep(randi_range(30,75))
		$StaticBody3D/CollisionShape3D.disabled = true
		navigation_mesh.bake_navigation_mesh()
		
		queue_free()
		
