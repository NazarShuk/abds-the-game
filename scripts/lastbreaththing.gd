extends "res://scripts/shake_control.gd"

@export var player : CharacterBody3D

func _enter_tree() -> void:
	set_multiplayer_authority(player.name.to_int())

func _process(delta: float) -> void:
	super._process(delta)
	
	visible = player.last_breath
	do_shake = player.last_breath
