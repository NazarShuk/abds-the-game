extends Node3D

func _ready() -> void:
	show_dialog("Godot gaymingling engine", "my name is godot, i made the enging", load("res://textures/icon.svg"))

func show_dialog(character_name : String, dialog : String, icon: Texture2D, duration = 5.0):
	$CanvasLayer/Dialog/AnimationPlayer.play("open_anim")
	$CanvasLayer/Dialog.show()
	$CanvasLayer/Dialog/TextureRect.texture = icon
	$CanvasLayer/Dialog/vertical/Label.text = character_name
	$CanvasLayer/Dialog/vertical/Label2.text = ""
	await $CanvasLayer/Dialog/AnimationPlayer.animation_finished
	$CanvasLayer/Dialog/AnimationPlayer.play("speak")
	$CanvasLayer/Dialog/vertical/Label2.text = dialog
	
	await $CanvasLayer/Dialog/AnimationPlayer.animation_finished
	await get_tree().create_timer(1, false).timeout
	
	$CanvasLayer/Dialog/AnimationPlayer.play_backwards("open_anim")
	await $CanvasLayer/Dialog/AnimationPlayer.animation_finished
	
	$CanvasLayer/Dialog.hide()
