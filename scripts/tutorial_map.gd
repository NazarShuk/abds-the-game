extends Node3D

func _ready() -> void:
	Game.on_game_started.connect(_game_started)
	
	await show_dialog("Mr.Azzu", 
	"Hey there goofball! We are gonna teach you how to play the game!clsTo walk around, use WASD, and to look around use your mouse.cls Also use shift to run, hold tab to use the minimap, and press g to emote.",
	load("res://textures/teacher_azzu.png"))
	
	await get_tree().create_timer(4, false).timeout
	
	$Book.global_position.y = 0.7
	await show_dialog("Mr.Azzu", 
	"I'm gonna assume that you figured it out by now.clsAnyways, see that green notebook over there? Go get it.",
	load("res://textures/teacher_azzu.png"))

func _game_started():
	await show_dialog("Player", 
	"owie",
	load("res://textures/player.png"))
	
	await show_dialog("Mr.Azzu", 
	"That was basically the entire game. Let me take it to the drawing board.",
	load("res://textures/teacher_azzu.png"))
	
	$CanvasLayer/FADE/AnimationPlayer.play("fade")
	await $CanvasLayer/FADE/AnimationPlayer.animation_finished
	
	get_tree().change_scene_to_file("res://scenes/tutorial_2d.tscn")

func show_dialog(character_name : String, dialog : String, icon: Texture2D, speed = 0.05):
	$CanvasLayer/Dialog/AnimationPlayer.play("open_anim")
	$CanvasLayer/Dialog.show()
	$CanvasLayer/Dialog/TextureRect.texture = icon
	$CanvasLayer/Dialog/vertical/Label.text = character_name
	$CanvasLayer/Dialog/vertical/Label2.text = ""
	await $CanvasLayer/Dialog/AnimationPlayer.animation_finished
	
	$CanvasLayer/Dialog/AnimationPlayer.play("speak")
	
	var chars = dialog.split("")
	var total_chars = chars.size()
	
	
	for idx in range(0, total_chars):
		var char = chars[idx]
		
		if char == "c" and chars[idx + 1] == "l" and chars[idx + 2] == "s":
			await get_tree().create_timer(speed * 20, false).timeout
			$CanvasLayer/Dialog/vertical/Label2.text = ""
			continue
		if char == "l" and chars[idx - 1] == "c" and chars[idx + 1] == "s":
			$CanvasLayer/Dialog/vertical/Label2.text = ""
			continue
		if char == "s" and chars[idx - 2] == "c" and chars[idx - 1] == "l":
			$CanvasLayer/Dialog/vertical/Label2.text = ""
			continue
		
		$CanvasLayer/Dialog/vertical/Label2.text += char
		$CanvasLayer/Dialog/blip.play()
		
		var wait_time = speed
		
		if char in [",", ".", "!", "?"]:
			wait_time *= 3
		
		await get_tree().create_timer(wait_time, false).timeout
		
	
	await get_tree().create_timer(1, false).timeout
	
	$CanvasLayer/Dialog/AnimationPlayer.play_backwards("open_anim")
	await $CanvasLayer/Dialog/AnimationPlayer.animation_finished
	
	$CanvasLayer/Dialog.hide()
