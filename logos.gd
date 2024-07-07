extends Node2D

var logos = [
"res://lgoos/android.png",
"res://lgoos/apple.png",
"res://lgoos/ea sports.png",
"res://lgoos/epoic.png",
"res://lgoos/godot.png",
"res://lgoos/google.png",
"res://lgoos/intel.png",
"res://lgoos/maxis.png",
"res://lgoos/microsoft.png",
"res://lgoos/rockstart games.png",
"res://lgoos/sony.png",
"res://lgoos/unity.png",
"res://lgoos/unreal.png",
"res://lgoos/valve.png"
]

func _ready():

	logos.shuffle()
	AudioVolume.load_values_and_apply()

func _on_timer_2_timeout():
	if logos.size() != 0:
		$CanvasLayer/TextureRect.texture = load(logos[0])
		logos.remove_at(0)


func _on_timer_timeout():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	
	get_tree().change_scene_to_file("res://game.tscn")
