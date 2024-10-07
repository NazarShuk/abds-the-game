extends Node3D

@export var is_open = false

var closed_mat : StandardMaterial3D = load("res://models/door_closed.tres")
var open_mat : StandardMaterial3D = load("res://models/door_open.tres")

func _ready():
	set_open(false)
	$MeshInstance3D2.hide()

@rpc("any_peer","call_local")
func set_open(open):
	is_open = open
	if !is_open:
		$MeshInstance3D3.material_override = closed_mat
		$MeshInstance3D.material_override = closed_mat
	else:
		$MeshInstance3D3.material_override = open_mat
		$MeshInstance3D.material_override = open_mat
