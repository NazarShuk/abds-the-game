extends Node3D



var skins = {
	0: {
		"front": "uid://mbp707vcisem",
		"back": "uid://uaunmtvsd4j4"
	},
	1: {
		"front": "uid://cbdunl7jdeyq",
		"back": "uid://dta0u30sd2fbk"
	},
	2: {
		"front": "uid://e481qnldgi3y",
		"back": "uid://dai6qepdbfr8d"
	},
	3: {
		"front": "uid://hdblcb4bt73n",
		"back": "uid://d1myp1gcenl1q"
	},
	4: {
		"front": "uid://dcgs0fxmh71wv",
		"back": "uid://blwkn3dly2c54"
	},
	5: {
		"front": "uid://2dp4oh8akf5w",
		"back": "uid://crc1l85w1qk0v"
	}
}

@onready var plane: MeshInstance3D = $Armature_001/Skeleton3D/Plane
@onready var skeleton: Skeleton3D = $Armature_001/Skeleton3D

@export var skin = 0
@export var head_rotation : float
var previous_skin = -1

func _ready() -> void:
	if !multiplayer.has_multiplayer_peer():
		$MultiplayerSynchronizer.queue_free()

func _process(delta: float) -> void:
	var neck_bone = skeleton.find_bone("Bone.002")
	
	skeleton.set_bone_pose_rotation(neck_bone, Quaternion.from_euler(Vector3(head_rotation, 0, 0)))
	
	if previous_skin != skin:
		pick_skin(skin)
		previous_skin = skin
	
func pick_skin(skin_id):
	var material : ShaderMaterial = plane.get_surface_override_material(0)
	
	material.set_shader_parameter("front_texture", load(skins[skin_id].front))
	material.set_shader_parameter("back_texture", load(skins[skin_id].back))
	
