extends Node3D

func _exit_tree():
	show()
	EndGameSingleton.current_skin = duplicate()
