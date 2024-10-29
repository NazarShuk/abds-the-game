extends Node

@export var true_animation : String
@export var false_animation : String
@export var param_name : String = "mr_azzu"

func _ready() -> void:
	if Game.game_params.get_param(param_name):
		get_parent().play(true_animation)
	else:
		get_parent().play(false_animation)
