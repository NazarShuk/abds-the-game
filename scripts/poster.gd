extends MeshInstance3D

@export var poster_collection_name : String
@export var posters : Array[PosterCollection]

func _ready() -> void:
	
	var poster_collection : PosterCollection
	
	for collection : PosterCollection in posters:
		if collection.name == poster_collection_name:
			poster_collection = collection
	
	if poster_collection:
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		
		var texture = poster_collection.get_random_poster()
		if texture:
			mat.albedo_texture = texture
		else:
			queue_free()
		
		material_override = mat
		
	else:
		printerr("Poster didnt find collection with name: ",poster_collection_name)
		
		queue_free()
