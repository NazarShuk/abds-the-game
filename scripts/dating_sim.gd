extends Control

var will_texture = PlaceholderTexture2D.new()

var _answer_choice = null
var gender = null

func _ready() -> void:
	
	await show_dialog("", "........", null, 0.1)
	await show_dialog("", "8:10 AMclsclsYou are almost out of time...clsclsThe door is going to be closed in 5 minutes...")
	await show_dialog("You", "Oh god please just give me a few minutes-", load("res://textures/player.png"))
	
	$AnimationPlayer.play("fall")
	
	
	await get_tree().create_timer(2, false).timeout
	$AudioStreamPlayer.play()
	await show_dialog("", "Owie, that hurt", will_texture)
	await show_dialog("", "Whoopsiecls wait who are you?clscls we haven't met before... are you perchance... a girl?", will_texture)
	
	gender = await prompt("Are you perchance... a girl?", ["girl", "boy"])
	
	if gender == "girl":
		await show_dialog("", "oclsclsa girl?..clsclsheh... good thing i can use my... heh... sigma rizz on the huzz", will_texture)
		await show_dialog("", "Are you a Sunkist? ‘Cause every time I see you, I freeze for 15 seconds... just starin’ at how cute you are.cls.cls..cls...clsFUCK THAT WAS SO BADcls ...focus william... you need to rizz up the huzz...cls*coughs*clsGirl, are you Mountain Dew? ‘Cause you got me stunned.clsSHIT...", will_texture)
	else:
		await show_dialog("", "oh what is up my G...clsclsbro i'm not sherry the game what", will_texture)
	await prompt("", ["What are you doing??", "..."])
	
	await show_dialog("William", "uhhh hiiiiiiii!! My name William!! Here take my number and call me back later", will_texture)
	
	$AnimationPlayer.play("go_away")
	await $AnimationPlayer.animation_finished
	
	await show_dialog("", "He handed you a note with his phone number and went away. You go to your class and the day continues as usual.")
	
	
	$ColorRect/AnimationPlayer.play("fade", -1, 0.5)
	await $ColorRect/AnimationPlayer.animation_finished
	$AudioStreamPlayer.stop()
	await get_tree().create_timer(2, false).timeout
	
	var do_call = await prompt("Call him?", ["yes", "no"])
	
	if do_call == "no":
		await show_dialog("", "clscls...wow...clsclsok get back to the menu then")
		get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")
		return
	
	for i in range(randi_range(2, 3)):
		$phone.play()
		await $phone.finished
	
	$investigations.play()
	await show_dialog("William", "Hello?", will_texture)
	
	var what_say = await prompt("what do you say", ["Hi, this is me.", "Hello, is this William?", "Bazinga"])
	
	match what_say:
		"Hello, is this William?":
			await show_dialog("William", "Yes hello this is me, we met today in the morning!!!", will_texture)
		"Hi, this is me.":
			await show_dialog("William", "YES HIIII", will_texture)
		"Bazinga":
			await show_dialog("William", "what the fuckclsclsoh it's you!!", will_texture)
	
	await show_dialog("William", "Uhhh... i was wondering if we could... perchance... go out on a date? ....cls pleaseclsclsuwu", will_texture)
	
	var go_out = await prompt("", ["Yeah sure!", "Uhhhhhh"])
	
	if go_out == "Yeah sure!":
		await show_dialog("William", "......clsDid you say yes?clsYIPPIEIEIEIEIEIEclscls okay let's meet at...", will_texture)
		
		await show_dialog("", "William and you planned out where you should go.clsclsYou get ready and go to the place.")
	else:
		await show_dialog("William", "......Really??clsclsNOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO", will_texture)
		
		$investigations.stop()
		await show_dialog("", "William hanged up.clsclsAfter a few days he killed himself.")
		
		get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")
		return
	$investigations.stop() 
	
func prompt(title: String, choices: Array[String]):
	for child in $Prompt/Panel/GridContainer.get_children():
		child.queue_free()
	$Prompt/Panel/Label.text = title
	
	_answer_choice = null
	
	for choice in choices:
		var button : Button = Button.new()
		button.text = choice
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		$Prompt/Panel/GridContainer.add_child(button)
		
		button.pressed.connect(func ():
			_answer_choice = choice
		)
	
	$Prompt/AnimationPlayer.play("open")
	await $Prompt/AnimationPlayer.animation_finished
	
	while _answer_choice == null:
		await get_tree().create_timer(0.1, false).timeout
	
	$Prompt/AnimationPlayer.play_backwards("open")
	await $Prompt/AnimationPlayer.animation_finished
	
	return _answer_choice

func show_dialog(character_name : String, dialog : String, icon: Texture2D = null, speed = 0.05):
	$Dialog/AnimationPlayer.play("open_anim")
	$Dialog.show()
	$Dialog/TextureRect.texture = icon
	$Dialog/vertical/Label.text = character_name
	$Dialog/vertical/Label2.text = ""
	await $Dialog/AnimationPlayer.animation_finished
	
	$Dialog/AnimationPlayer.play("speak")
	
	var chars = dialog.split("")
	var total_chars = chars.size()
	
	
	for idx in range(0, total_chars):
		var char = chars[idx]
		
		if char == "c" and chars[idx + 1] == "l" and chars[idx + 2] == "s":
			if !Input.is_action_pressed("jump"):
				await get_tree().create_timer(speed * 20, false).timeout
			$Dialog/vertical/Label2.text = ""
			continue
		if char == "l" and chars[idx - 1] == "c" and chars[idx + 1] == "s":
			$Dialog/vertical/Label2.text = ""
			continue
		if char == "s" and chars[idx - 2] == "c" and chars[idx - 1] == "l":
			$Dialog/vertical/Label2.text = ""
			continue
		
		$Dialog/vertical/Label2.text += char
		$Dialog/blip.play()
		
		var wait_time = speed
		
		if char in [",", ".", "!", "?"]:
			wait_time *= 3
		
		if Input.is_action_pressed("jump"):
			wait_time *= 0.1
		
		await get_tree().create_timer(wait_time, false).timeout
		
	 
	await get_tree().create_timer(1, false).timeout
	
	$Dialog/AnimationPlayer.play_backwards("open_anim")
	await $Dialog/AnimationPlayer.animation_finished
	
	$Dialog.hide()
