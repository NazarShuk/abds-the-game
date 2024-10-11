extends "res://scripts/end.gd"

@export var player_obj : NodePath

func _ready():
	super._ready()
	
	get_node(player_obj).add_child(EndGameSingleton.current_skin)
