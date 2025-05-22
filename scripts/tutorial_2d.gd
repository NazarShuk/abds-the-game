extends CanvasLayer

func _ready() -> void:
	GuiManager.show_tip_once("tutorial_complete", "", 0)
	
	await get_tree().create_timer(1, false).timeout
	
	await show_dialog("Mr.Azzu", 
	"ABDS The Game is all about collecting notebooks, and trying to not \"dissapear\"",
	load("res://textures/teacher_azzu.png"))
	
	$Control/AnimatedSprite2D.play("stuff")
	
	await show_dialog("Mr.Azzu", 
	"One of the teachers, Ms.Leahy will be constantly chasing you down... And she will get faster when you collect more notebooks.",
	load("res://textures/teacher_azzu.png"))
	
	$Control/AnimatedSprite2D.play("items")
	
	await show_dialog("Mr.Azzu", 
	"There are a lot of vending machines around the map to help you. You get items from them.clsFor example, fruit snacks make you faster. Mtn Dew stops Ms.Leahy for 5 seconds, and the square pizza will make you jump really high.clsThere are more items in the game of course.",
	load("res://textures/teacher_azzu.png"))
	
	$Control/AnimatedSprite2D.play("exit")
	
	await show_dialog("Mr.Azzu", 
	"After you collect all the notebooks, you will need to escape. Be careful tho, if you get caught you will have to restart all over again.",
	load("res://textures/teacher_azzu.png"))
	
	$Control/AnimatedSprite2D.play("coolio")
	
	await show_dialog("Mr.Azzu", 
	"That should be it for now. You will get more tooltips when you play the game. Bye goofball!",
	load("res://textures/teacher_azzu.png"))
	
	$Label.show()
	while !Input.is_anything_pressed():
		await get_tree().create_timer(0.01, false).timeout
	
	$AnimationPlayer.play("outro")
	await get_tree().create_timer(0.5, false).timeout
	
	GuiManager.show_tip_once("tutorial_complete", "")
	get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")

func show_dialog(character_name : String, dialog : String, icon: Texture2D, speed = 0.05):
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
		
		await get_tree().create_timer(wait_time, false).timeout
		
	
	await get_tree().create_timer(1, false).timeout
	
	while !Input.is_anything_pressed():
		await get_tree().create_timer(0.01, false).timeout
	
	$Dialog/AnimationPlayer.play_backwards("open_anim")
	await $Dialog/AnimationPlayer.animation_finished
	
	$Dialog.hide()
