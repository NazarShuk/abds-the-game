extends Node3D

@export var rooms : Array[PackedScene]

var time = 0

@onready var bpm = $boss_loop.stream.bpm
@onready var bps = 60 / bpm

var beats = 0

var room_z = 20
var spawned_rooms = []
var total_rooms = 0

func _ready() -> void:
	$boss_intro.play()
	await $boss_intro.finished
	$Dariel.chase = true
	$CanvasLayer.show()
	
	spawn_new_room()
	$Player/Head/Camera3D.make_current()
	$WorldEnvironment.environment.background_energy_multiplier = 5
	$Intro.queue_free()
	$boss_loop.play()

func spawn_new_room():
	var room = rooms.pick_random().instantiate()
	add_child(room)
	room.global_position.z = room_z
	room_z += 20
	total_rooms += 1
	spawned_rooms.append(room)
	
	room.player_entered.connect(func (player):
		if $Dariel.times_hit < 1:
			spawn_new_room()
		else:
			do_the_thing()
	)
	
	if spawned_rooms.size() > 5:
		spawned_rooms[0].queue_free()
		spawned_rooms.remove_at(0)
	
	if total_rooms % 5 == 0 and total_rooms != 0:
		if $Player.cloroxes_left < 3:
			$Player.cloroxes_left += 1

func do_the_thing():
	await get_tree().create_timer(1.5, false).timeout
	$Final_anim.global_position.z = room_z + 5
	$Final_anim/Camera3D.make_current()
	$Final_anim/AnimationPlayer.play("fall")
	$boss_loop.stop()
	$Final_anim.show()
	$Player/CanvasLayer.hide()
	$CanvasLayer.hide()
	
	# just in case
	$Dariel.queue_free()
	$Player.queue_free()
	
	for room in spawned_rooms:
		room.get_node("AnimationPlayer").play_backwards("appear")
	
	GuiManager.show_cursor()

var _previous_times_hit = 0

func _process(delta: float) -> void:
	$WorldEnvironment.environment.background_energy_multiplier = lerp($WorldEnvironment.environment.background_energy_multiplier, 1.0, delta * 15)
	if get_node_or_null("Player"):
		$Player/CanvasLayer.rotation = lerp($Player/CanvasLayer.rotation, 0.0, delta * 15)
	
	$Final_anim/Camera3D.fov = lerp($Final_anim/Camera3D.fov, 75.0, delta * 15)
	$CanvasLayer/Label.scale = lerp($CanvasLayer/Label.scale, Vector2(1, 1), delta * 15)
	
	if $boss_loop.playing or $boss_loop2.playing:
		time += delta * $boss_loop2.pitch_scale
	
	if time >= bps:
		$WorldEnvironment.environment.background_energy_multiplier = 1.2
		if get_node_or_null("Player"):
			if beats % 2 == 0:
				$Player/CanvasLayer.rotation = 0.01
			else:
				$Player/CanvasLayer.rotation = -0.01
		
		if beats % 2 == 0:
			$CanvasLayer/Label.scale = Vector2(0.8, 1.2)
		else:
			$CanvasLayer/Label.scale = Vector2(1.2, 0.8)
		
		$Final_anim/Camera3D.fov = 75.5
		time -= bps
		beats += 1
	
	if get_node_or_null("Player") and get_node_or_null("Dariel"):
		if $Player.global_position.distance_to($Dariel.global_position) < 1:
			play_death()
		
		
		if _previous_times_hit != $Dariel.times_hit:
			num_transition()
			_previous_times_hit = $Dariel.times_hit
			
		

func num_transition():
	var new_val = $Dariel.times_hit
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($CanvasLayer/Label, "rotation_degrees", 180, 0.25)
	await tween.finished
	$CanvasLayer/Label.text = str(10 - new_val)
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($CanvasLayer/Label, "rotation_degrees", 359, 0.25)

func play_death():
	$Death_anim.show()
	$Death_anim.global_position.z = $Player.global_position.z
	$Death_anim.global_position.x = $Player.global_position.x
	$Death_anim/AnimationPlayer.play("ded")
	$Death_anim/Camera3D.make_current()
	
	$Dariel.queue_free()
	$Player.queue_free()
	$boss_loop.stop()
	$CanvasLayer.hide()
	
	await $Death_anim/AnimationPlayer.animation_finished
	
	get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")

func show_dialog(character_name : String, dialog : String, icon: Texture2D = null, speed = 0.05):
	$Dialog/Dialog/AnimationPlayer.play("open_anim")
	$Dialog/Dialog.show()
	$Dialog/Dialog/TextureRect.texture = icon
	$Dialog/Dialog/vertical/Label.text = character_name
	$Dialog/Dialog/vertical/Label2.text = ""
	await $Dialog/Dialog/AnimationPlayer.animation_finished
	
	$Dialog/Dialog/AnimationPlayer.play("speak")
	
	var chars = dialog.split("")
	var total_chars = chars.size()
	
	for idx in range(0, total_chars):
		var char = chars[idx]
		
		if char == "c" and chars[idx + 1] == "l" and chars[idx + 2] == "s":
			$Dialog/Dialog/vertical/Label2.text = ""
			continue
		if char == "l" and chars[idx - 1] == "c" and chars[idx + 1] == "s":
			$Dialog/Dialog/vertical/Label2.text = ""
			continue
		if char == "s" and chars[idx - 2] == "c" and chars[idx - 1] == "l":
			$Dialog/Dialog/vertical/Label2.text = ""
			continue
		
		$Dialog/Dialog/vertical/Label2.text += char
		$Dialog/Dialog/blip.play()
		
		var wait_time = speed
		
		if char in [",", ".", "!", "?"]:
			wait_time *= 3
		
		if Input.is_action_pressed("jump"):
			wait_time *= 0.1
		
		await get_tree().create_timer(wait_time, false).timeout
		
	 
	await get_tree().create_timer(1, false).timeout
	
	$Dialog/Dialog/AnimationPlayer.play_backwards("open_anim")
	await $Dialog/Dialog/AnimationPlayer.animation_finished
	
	$Dialog/Dialog.hide()


func _on_spare_pressed() -> void:
	$Final_anim/AnimationPlayer.play("spare")
	await $Final_anim/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file.call_deferred("res://scenes/bossfight_spare.tscn")

func _on_kill_pressed() -> void:
	$Final_anim/AnimationPlayer.play("kill")
	await $Final_anim/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file.call_deferred("res://scenes/bossfight_kill.tscn")
