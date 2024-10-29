extends Resource

class_name PosterCollection

@export var name : String
@export var textures : Array[CompressedTexture2D]

func get_random_poster():
	var poster = textures.pick_random()
	
	if poster:
		return poster
	else:
		return null
