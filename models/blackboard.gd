extends StaticBody3D

var texts = [
	"res://models/blackboard/blackboard (1).png",
	"res://models/blackboard/blackboard (2).png",
	"res://models/blackboard/blackboard (3).png",
	"res://models/blackboard/blackboard (4).png",
	"res://models/blackboard/blackboard (5).png",
	"res://models/blackboard/blackboard (6).png",
	"res://models/blackboard/blackboard (7).png",
	"res://models/blackboard/blackboard (8).png",
	"res://models/blackboard/blackboard (9).png",
]

func _ready():
	var material: StandardMaterial3D = StandardMaterial3D.new()
	
	material.albedo_texture = load(texts.pick_random())
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	$Text1.set_surface_override_material(0,material)
	
