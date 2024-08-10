extends FogVolume

var navigation_mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer.is_server():
		await get_tree().create_timer(2).timeout
		$StaticBody3D/CollisionShape3D.disabled = false
		await get_tree().create_timer(5).timeout
		navigation_mesh.bake_navigation_mesh()
		await get_tree().create_timer(randi_range(30,75)).timeout
		$StaticBody3D/CollisionShape3D.disabled = true
		navigation_mesh.bake_navigation_mesh()
		
		queue_free()
		


