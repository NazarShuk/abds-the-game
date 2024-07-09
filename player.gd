extends CharacterBody3D

const OG_SPEED = 5.0
var SPEED = OG_SPEED
var is_boosted = false

const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var books_collected = 0

var is_running = false
var stamina = 75
var can_run = true
var is_moving = false
var can_move = true

@onready var progress_bar: ProgressBar = $CanvasLayer/Control/ProgressBar

var is_dead = false

@onready var ray = $RayCast3D

var cam_fov = 75
var can_cam_move = true
@export var steam_name : String = "Loading..."

var revive_poses = [Vector3(0, 1.2, -10), Vector3(-18, 1.2, -24), Vector3(-26, 1.2, -57), Vector3(34, 1.2, -47), Vector3(8, 1.2, -28)]

var is_suspended = false


var is_on_top = false
var on_top_counter = 0

@onready var default = $visual_body/Default
@onready var perfect = $visual_body/Perfect
@onready var impossible = $visual_body/Impossible
@onready var freaky = $visual_body/Freaky

var can_get_item = true

@onready var camera_3d = $CanvasLayer2/SubViewportContainer/SubViewport/Camera3D

var leahy_dst = 0


# Voice chat (maybe)
@onready var input = $Voice/input
var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback
@export var outputPath : NodePath
var inputThreshold = 0.08

var receive_buffer := PackedFloat32Array()

var credits = 0
var can_use_shop = true

func setup_voice(_id):
	if is_multiplayer_authority():
		$Voice/input.stream = AudioStreamMicrophone.new()
		$Voice/input.play()
		effect = AudioServer.get_bus_effect(5,4)
		
	get_node(outputPath).play()
	playback = $Voice/AudioStreamPlayer.get_stream_playback()

func processMic():
	var stereoData : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if stereoData.size() > 0:
		var data = PackedFloat32Array()
		data.resize(stereoData.size())
		var maxAmplitude := 0.0
		
		for i in range(stereoData.size()):
			var value = (stereoData[i].x + stereoData[i].y) / 2
			maxAmplitude = max(value,maxAmplitude)
			data[i] = value
		
		if maxAmplitude < 0.1:
			set_mouth(0)
		elif maxAmplitude < 0.2:
			set_mouth(1)
		elif maxAmplitude < 0.3:
			set_mouth(2)
		elif maxAmplitude < 0.4:
			set_mouth(3)
		elif maxAmplitude > 0.5:
			set_mouth(4)
		else:
			set_mouth(0)
		
		if maxAmplitude < inputThreshold:
			return
		

		
		send_voice_data.rpc(data)
		#send_voice_data(data) #local test

@rpc("any_peer","call_remote","unreliable_ordered")
func send_voice_data(data:PackedFloat32Array):
	receive_buffer.append_array(data)

func process_voice():
	playback = $Voice/AudioStreamPlayer.get_stream_playback()
	
	if receive_buffer.size() <= 0:
		return
	elif receive_buffer.size() >= 2048:
		receive_buffer = receive_buffer.slice(0,2048)
		#playback.clear_buffer()

	for i in range(min(playback.get_frames_available(),receive_buffer.size())):
		playback.push_frame(Vector2(receive_buffer[0],receive_buffer[0]))
		receive_buffer.remove_at(0)

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	if !Allsingleton.non_steam:
		$nametag.text = Steam.getPersonaName()
		steam_name = Steam.getPersonaName()
	else:
		$nametag.text = "Offline player"
		steam_name = "Offline player"

	if is_multiplayer_authority():
		$CanvasLayer.show()
		get_cur_item()
		get_parent().hide_menu()
		$CanvasLayer2/SubViewportContainer/SubViewport.audio_listener_enable_2d = true
		$CanvasLayer2/SubViewportContainer/SubViewport.audio_listener_enable_3d = true
		$CanvasLayer2.process_mode = Node.PROCESS_MODE_INHERIT
		#$Local.stream_mix_rate = float(current_sample_rate)
		
		



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_multiplayer_authority():
		
		setup_voice(name.to_int())
		var skins = $visual_body.get_children()
		for skin in skins:
			if skin.name != "Mouth":
				skin.hide()
			
		var picked_skin = false
		
		if Achievements.check_achievement("impossible_ending"):
			if Achievements.picked_skin == 3:
				impossible.show()
				picked_skin = true
		if Achievements.check_achievement("perfect_ending"):
			if Achievements.picked_skin == 2:
				perfect.show()
				picked_skin = true
		if Achievements.check_achievement("freaky_ending"):
			if Achievements.picked_skin == 1:
				freaky.show()
				picked_skin = true
		
		if picked_skin == false:
			default.show()
		
		

var is_freaky = false

func _physics_process(delta):
	process_voice()
	if is_multiplayer_authority():
		$CanvasLayer/Control/Shop/ColorRect/timer.text = str(floor($"CanvasLayer/Control/Shop/shop timer".time_left)) + "s left"
		
		$CanvasLayer/Control/Shop/ColorRect/Label2.text = str(credits) + " credits"
		# Voice chat
		processMic()
		inputThreshold = AudioVolume.mic_threshold
		
		leahy_dst = global_position.distance_to(get_parent().get_node("EvilLeahy").global_position)
		
		if Input.is_action_just_pressed("debug"):
			pick_item(2)
		
		if (10 - leahy_dst) > 0:
			var strength = 1/leahy_dst+0.01
			camera_3d.h_offset = randf_range(-strength,strength) / 5
			camera_3d.v_offset = randf_range(-strength,strength) / 5
		else:
			camera_3d.h_offset = 0
			camera_3d.v_offset = 0
		



		if global_position.z > 15 && !is_freaky:
			is_freaky = true
			get_parent().skibidi.rpc()
			# freaky ending

		if global_position.y >= 3.727:
			is_on_top = true
		else:
			is_on_top = false
		
		
		
		# Add the gravity.
		if not is_on_floor() and not is_dead:
			velocity.y -= gravity * delta

		$AudioStreamPlayer3D.volume_db = -80

		if Input.is_action_just_pressed("sprint"):
			is_running = true
		elif Input.is_action_just_released("sprint"):
			is_running = false

		velocity.x = 0
		velocity.z = 0

		if get_parent().canPlayersMove:
			if can_move and not is_suspended:
				if can_cam_move:
					var turning = Input.get_axis("turn_right", "turn_left")
					rotate_y(deg_to_rad(turning) * 1.5)
					if Input.is_action_pressed("forward"):
						translate(Vector3(0, 0, SPEED * -delta))
						$AudioStreamPlayer3D.volume_db = 0
						is_moving = true
					elif Input.is_action_pressed("back"):
						translate(Vector3(0, 0, SPEED * delta))
						$AudioStreamPlayer3D.volume_db = 0
						is_moving = true

					if Input.is_action_pressed("left"):
						translate(Vector3(SPEED * -delta, 0, 0))
						$AudioStreamPlayer3D.volume_db = 0
						is_moving = true

					elif Input.is_action_pressed("right"):
						translate(Vector3(SPEED * delta, 0, 0))
						$AudioStreamPlayer3D.volume_db = 0
						is_moving = true

					if (
						Input.is_action_just_released("back")
						or Input.is_action_just_released("forward")
						or Input.is_action_just_released("left")
						or Input.is_action_just_released("right")
					):
						is_moving = false

					if Input.is_action_just_pressed("interact"):
						if ray.get_collider() and get_cur_item() == -1:

							if ray.get_collider().is_in_group("vending_machine"):
								get_parent().use_vending_machine.rpc(name.to_int())
						if ray.get_collider():
							if ray.get_collider().is_in_group("shop"):
								print("shop")
								open_shop()
								
					
					if Input.is_action_just_pressed("give"):
						if get_cur_item() == 3:
							var evil_leahy = get_tree().get_first_node_in_group("enemies")
							var distance = global_position.distance_to(evil_leahy.global_position)

							if distance < 15:
								pick_item(-1)
								get_parent().appease_leahy.rpc(steam_name,5)
							else:
								var fox = get_tree().get_first_node_in_group("fox")
								var dist = global_position.distance_to(fox.global_position)
								if dist < 15:
									pick_item(-1)
									get_parent().mr_fox_collect.rpc()
						elif get_cur_item() == 5:
							var evil_leahy = get_tree().get_first_node_in_group("enemies")
							var distance = global_position.distance_to(evil_leahy.global_position)

							if distance < 25:
								pick_item(-1)
								get_parent().appease_leahy.rpc(steam_name,15)
					
					if Input.is_action_just_pressed("use_item"):
						if get_cur_item() == 0:
							pick_item(-1)
							is_boosted = true
							$FruitSnacksTimer.start()
						elif get_cur_item() == 1:
							pick_item(-1)
							spawn_clorox.rpc()
						elif get_cur_item() == 2:
							pick_item(-1)
							velocity.y += 10
							shart.rpc()
						
						elif get_cur_item() == 4:
							
							squeak.rpc()
							pick_item(-1)
							get_parent().start_da_pacer.rpc(name.to_int()) # i want to kms because of this
						

		move_and_slide()

		progress_bar.value = lerp(progress_bar.value, float(stamina), 0.2)
		camera_3d.fov = lerp(camera_3d.fov, float(cam_fov), 0.1)

		if Input.is_action_just_pressed("escape"):
			$CanvasLayer/Control/Menu.visible = !$CanvasLayer/Control/Menu.visible
			can_cam_move = !$CanvasLayer/Control/Menu.visible

			if $CanvasLayer/Control/Menu.visible == true:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if get_tree():
			for obj: Node3D in get_tree().get_nodes_in_group("localface"):
				obj.look_at(global_position)
				obj.rotation_degrees.x = 0
				obj.rotation_degrees.z = 0

		if Input.is_action_just_pressed("throw"):
			pick_item(-1)

		if get_parent().leahy_look:
			var target = get_tree().get_nodes_in_group("enemies")[0].global_position

			look_at(target)
			cam_fov = 10
		
		if get_parent().pacer_deadly:
			var dst = global_position.distance_to(get_parent().get_node("FakeFox").global_position)
			if dst > 5:
				$CanvasLayer/Control/Control.show()
			else:
				$CanvasLayer/Control/Control.hide()
			
			if dst > 10:
				die("fox")
				$CanvasLayer/Control/Control.hide()
				
		camera_3d.current = true
		camera_3d.global_position = global_position + Vector3(0,0.5,0)
		camera_3d.global_rotation.y = global_rotation.y
		#camera_3d.global_rotation.x = global_rotation.x
		$CanvasLayer2.visible = true

func _input(event):
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		if can_move:
			if can_cam_move:
				rotate_y(deg_to_rad(event.relative.x * -0.3))
				if get_parent().do_vertical_camera:
					# funni
					camera_3d.rotate_x(deg_to_rad(event.relative.y * -0.3))


func _on_area_3d_area_entered(area):
	if !is_multiplayer_authority():
		return
	if is_dead:
		return
	if area.get_parent().is_in_group("Book"):
		get_parent().on_collect_book.rpc(name.to_int(), area.get_parent().name,true)
		Achievements.books_collected += 1
		Achievements.save_all()
	elif area.get_parent().is_in_group("enemies") and get_parent().game_started == true:
		if get_parent().absent == false:
			die("leahy")
			
	elif area.name == "Landmine" and get_parent().game_started == true:
		
		die("mine")

		get_parent().on_collect_book.rpc(name.to_int(), area.name,true)
		
	elif area.name == "azzu" and get_parent().azzu_angered == true:
		die("azzu")
		get_parent().azzu_dont_steal.rpc()
	elif area.name == "gainy":
		#die("gainy")
		get_parent().stop_gainy.rpc(name.to_int())


func _on_timer_timeout():
	if !is_multiplayer_authority():
		return
	if is_running and is_moving:
		if stamina > 0:
			if can_run:
				stamina -= 1
				if !is_boosted:
					SPEED = OG_SPEED * 2
					if !get_parent().leahy_look:
						cam_fov = 100
				else:
					SPEED = OG_SPEED * 4
					if !get_parent().leahy_look:
						cam_fov = 120
		else:
			is_running = false
			can_run = false
			$Stamina_timeout.start()
	else:
		if !is_boosted:
			SPEED = OG_SPEED
			if !get_parent().leahy_look:
				cam_fov = 75
		else:
			SPEED = OG_SPEED * 2
			if !get_parent().leahy_look:
				cam_fov = 100
		if stamina <= 75:
			stamina += 1


func _on_stamina_timeout_timeout():
	if !is_multiplayer_authority():
		return
	can_run = true


func _on_revive_timer_timeout():

	if not is_suspended:
		global_position = get_parent().get_node("PlayerSpawns").get_children().pick_random().global_position
		get_parent().set_player_dead.rpc(name.to_int(), false,false)
	else:
		global_position = Vector3(45, 1.2, -43)
		get_parent().set_player_dead.rpc(name.to_int(), true,false)
	$"CanvasLayer/Control/Died thing".hide()
	AudioServer.set_bus_mute(1, false)
	AudioServer.set_bus_mute(2, false)
	is_dead = false
	$visual_body.global_rotation_degrees.x = 0
	can_move = true
	$CollisionShape3D.disabled = false


func pick_item(item: int):
	for i in $Hand.get_children():
		i.hide()

	if item != -1:
		$Hand.get_child(item).show()


func get_cur_item():
	var id = -1
	for i in range(0, $Hand.get_children().size()):
		if $Hand.get_children()[i].visible == true:
			id = i
			break

	return id


@rpc("any_peer", "call_local")
func choose_item():
	if can_get_item:
		can_get_item = false
		
		var items =   [0, 1, 2, 3, 4, 5]
		var chances = [37.5, 25, 12.5, 15, 2.5, 7.5]
		
		pick_item(pick_random_weighted(items,chances))

func pick_random_weighted(items: Array, chances: Array) -> Variant:
	var total_weight = chances.reduce(func(acc, weight): return acc + weight, 0.0)
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for i in range(items.size()):
		cumulative_weight += chances[i]
		if random_value <= cumulative_weight:
			return items[i]
	
	# Fallback in case of rounding errors
	return items[-1]

func _on_fruit_snacks_timer_timeout():
	is_boosted = false


@rpc("any_peer", "call_local")
func spawn_clorox():
	var packed_clorox = load("res://Clorox Wipes.tscn")
	var clorox: StaticBody3D = packed_clorox.instantiate()

	get_parent().add_child(clorox)

	clorox.initial_pos = $RayCast3D.global_position
	clorox.global_position = $RayCast3D.global_position
	clorox.global_rotation = $RayCast3D.global_rotation
	clorox.launcher = name.to_int()
	clorox.add_to_group("clorox_wipes")


@rpc("any_peer", "call_local")
func shart():
	var sp = AudioStreamPlayer3D.new()

	sp.stream = load("res://shart.mp3")
	sp.bus = "Dialogs"
	get_parent().add_child(sp)
	sp.global_position = global_position
	sp.play()


func _on_continue_btn_pressed():
	$CanvasLayer/Control/Menu.visible = !$CanvasLayer/Control/Menu.visible
	can_cam_move = !$CanvasLayer/Control/Menu.visible

	if $CanvasLayer/Control/Menu.visible == true:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_disconnect_btn_pressed():
	$CanvasLayer/Control/Menu/Main/DisconnectBtn.disabled = true
	if !multiplayer.is_server():
		print(name,"not server")
		multiplayer.multiplayer_peer.close()
		get_tree().reload_current_scene()
	else:
		get_parent().end_game.rpc("none")

@rpc("any_peer","call_local")
func die(cause):
	if is_dead: return
	$visual_body.global_rotation_degrees.x = 0
	can_move = false
	if cause != "mine":
		get_parent().set_player_dead.rpc(name.to_int(), true,true)
	else:
		if get_parent().landmine_death:
			get_parent().set_player_dead.rpc(name.to_int(), true,true)
		else:
			get_parent().set_player_dead.rpc(name.to_int(), true,false)
	$"CanvasLayer/Control/Died thing".show()
	$ReviveTimer.start(get_parent().death_timeout)
	is_dead = true
	AudioServer.set_bus_mute(1, true)
	AudioServer.set_bus_mute(2, true)
	$"CanvasLayer/Control/Died thing/AudioStreamPlayer".play()
	#TODO: make this work $CollisionShape3D.disabled = true
	Achievements.deaths += 1
	Achievements.save_all()
	$CanvasLayer/Control/Control.hide()
	close_shop()
	if cause == "leahy":
		$"CanvasLayer/Control/Died thing/jumpscare".play()
		if get_parent().do_silent_lunch:
			var chance = randi_range(0, 2)
			if chance == 0:
				$CanvasLayer/Control/silentLunch.show()
				$CanvasLayer/Control/silentLunch.text = "You got silent lunch\nyou can leave in " + str(get_parent().silent_lunch_duration)
				is_suspended = true
				$"Silent Lunch".start(get_parent().silent_lunch_duration)

	elif cause == "mine":
		$"CanvasLayer/Control/Died thing/jumpscare2".play()
	elif cause == "wall":
		$"CanvasLayer/Control/Died thing/jumpscare3".play()
	elif cause == "fox":
		$"CanvasLayer/Control/Died thing/jumpscare4".play()
	elif cause == "azzu":
		$"CanvasLayer/Control/Died thing/jumpscare5".play()
	elif cause == "gainy":
		$"CanvasLayer/Control/Died thing/jumpscare6".play()



func _on_silent_lunch_timeout():
	is_suspended = false
	get_parent().set_player_dead.rpc(name.to_int(), false,false)
	$CanvasLayer/Control/silentLunch.hide()


func _on_anti_wall_walk_timeout():
	if is_on_top:
		on_top_counter += 1

		if on_top_counter == 10:
			die("wall")
			on_top_counter = 0
			global_position.y = 1
	else:
		on_top_counter = 0

@rpc("any_peer","call_local")
func squeak():
	var sp = AudioStreamPlayer.new()

	sp.stream = load("res://squeak.mp3")
	sp.bus = "Dialogs"
	get_parent().add_child(sp)
	sp.play()

@rpc("any_peer","call_local")
func server_pos(pos: Vector3):
	global_position = pos

func _on_item_delay_timeout():
	can_get_item = true

func open_shop():
	if can_use_shop:
		$CanvasLayer/Control/Shop.show()
		$CanvasLayer/Control/Shop/AudioStreamPlayer.play()
		can_cam_move = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		AudioServer.set_bus_solo(6,true)
		get_parent().set_player_dead.rpc(name.to_int(), true,false)
		can_use_shop = false
		$ShopTimeout.start(get_parent().shop_timeout)
		get_parent().shop.hide()
		$"CanvasLayer/Control/Shop/shop timer".start()
		$CanvasLayer/Control/Shop/ColorRect/MainPanel.show()
		$"CanvasLayer/Control/Shop/ColorRect/question panel".hide()
		$"CanvasLayer/Control/Shop/ColorRect/rewards panel".hide()

func close_shop():
	$CanvasLayer/Control/Shop.hide()
	$CanvasLayer/Control/Shop/AudioStreamPlayer.stop()
	can_cam_move = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioServer.set_bus_solo(6,false)
	get_parent().set_player_dead.rpc(name.to_int(), false,false)
	$"CanvasLayer/Control/Shop/shop timer".stop()
	

func _on_shop_timeout_timeout():
	can_use_shop = true
	get_parent().shop.show()

func _on_credits_btn_pressed():
	$"CanvasLayer/Control/Shop/ColorRect/question panel".show()
	$CanvasLayer/Control/Shop/ColorRect/MainPanel.hide()
	generate_show_question()
	

func _on_shop_timer_timeout():
	close_shop()

func _on_rewards_btn_pressed():
	$CanvasLayer/Control/Shop/ColorRect/MainPanel.hide()
	$"CanvasLayer/Control/Shop/ColorRect/rewards panel".show()

@onready var item_list : ItemList = $"CanvasLayer/Control/Shop/ColorRect/question panel/ItemList"
var right_ans_index 

func generate_show_question():
	var num1 = randi_range(33,99)
	var num2 = randi_range(33,99)
	var ans = num1 + num2
	
	var right_choice = randi_range(0,4)
	
	$"CanvasLayer/Control/Shop/ColorRect/question panel/Label2".text = str(num1) + " + " + str(num2)
	item_list.clear()
	print("right choice: ",right_choice)
	for i in range(0,4):
		if i != right_choice:
			item_list.add_item(str(ans + randi_range(-5,5)))
		else:
			
			right_ans_index = item_list.add_item(str(ans))

func _on_item_list_item_clicked(index, _at_position, _mouse_button_index):
	print(index,right_ans_index)

	if index == right_ans_index:
		credits += 5
		generate_show_question()
		$CanvasLayer/Control/Shop/correct.play()
	else:
		$CanvasLayer/Control/Shop/incorrect.play()
		close_shop()

func set_mouth(mouth_id):
		
	var mouth : Node3D
	
	for sk : Node3D in $visual_body.get_children():
		if sk.visible:
			mouth = sk.get_node("Mouth")
			break 
	
	for m in mouth.get_children():
		if m is Node3D:
			m.hide()
	mouth.get_node(NodePath(str(mouth_id))).show()

func _on_buy_book_pressed():
	if credits >= 20:
		credits -= 20
		close_shop()
		get_parent().on_collect_book.rpc(name.to_int(), "book1",true)
		Achievements.books_collected += 1
		Achievements.save_all()
		
		var a = AudioStreamPlayer.new()
		a.stream = load("res://money.mp3")
		a.bus = "Dialogs"
		a.play()




func _on_buy_duck_pressed():
	if credits >= 10:
		credits -= 10
		close_shop()
		pick_item(4)
		
		var a = AudioStreamPlayer.new()
		a.stream = load("res://money.mp3")
		a.bus = "Dialogs"
		a.play()
