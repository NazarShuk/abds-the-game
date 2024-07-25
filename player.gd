extends CharacterBody3D

const OG_SPEED = 6.0
var SPEED = OG_SPEED
var boosts = {}
var is_boosted = false

const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var books_collected = 0

var is_running = false
var stamina = 75
var can_run = true
var is_moving = false
var can_move = true

@onready var progress_bar: ProgressBar = $"CanvasLayer/Control/Progress bar handler/ProgressBar"
@onready var progress_bar_handler = $"CanvasLayer/Control/Progress bar handler"

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

@onready var camera_3d = $CanvasLayer2/SubViewportContainer/SubViewport/XROrigin3D/Camera3D
@onready var minimap_cam = $Minimap/Camera3D

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

@onready var controls_text = get_parent().controls_text

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
		get_parent().hide_menu()
		$CanvasLayer2/SubViewportContainer/SubViewport.audio_listener_enable_2d = true
		$CanvasLayer2/SubViewportContainer/SubViewport.audio_listener_enable_3d = true
		$CanvasLayer2.process_mode = Node.PROCESS_MODE_INHERIT
		#$Local.stream_mix_rate = float(current_sample_rate)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_multiplayer_authority():
		$visual_body.hide()
		
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
var can_use_breaker = true
var can_use_coffee = true

var hand_target_y = -0.5
var can_toilet_tp = true

const push_force = 1.0

func _physics_process(delta):
	process_voice()
	if is_multiplayer_authority():
		
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			# If the collider is a RigidBody
			if collider is RigidBody3D:
				# Calculate the push direction
				var push_direction = collision.get_normal()
				
				# Apply the force to the RigidBody
				get_parent().push_item.rpc(collider.get_path(),push_direction,push_force)
				#collider.apply_central_impulse(-push_direction * push_force)
		
		control_text_setters()
		
		$CanvasLayer/Control/Minimap.visible = is_minimap_open
		
		if Input.is_action_just_pressed("open_minimap"):
			if !is_shop_open:
				is_minimap_open = !is_minimap_open
				if is_minimap_open:
					$Minimap.process_mode = Node.PROCESS_MODE_INHERIT
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					can_cam_move = false
				else:
					$Minimap.process_mode = Node.PROCESS_MODE_DISABLED
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					can_cam_move = true
		
		minimap_cam.size = lerp(minimap_cam.size,float(minimap_zoom),0.25)
		minimap_zoom = clamp(minimap_zoom,5,95)
		
		var final_multiplier = 1
		for b in boosts:
			final_multiplier += boosts[b]
		
		SPEED = clamp(OG_SPEED * final_multiplier,0,99999)
		if !get_parent().leahy_look:
			if final_multiplier != 1:
				cam_fov = 75 + final_multiplier * 15
			else:
				cam_fov = 75
		$Hand.position.y = lerp($Hand.position.y,hand_target_y,0.25)
		
		$CanvasLayer/Control/Shop/ColorRect/timer.text = str(floor($"CanvasLayer/Control/Shop/shop timer".time_left)) + "s left"
		
		$CanvasLayer/Control/Shop/ColorRect/Label2.text = str(credits) + " credits"
		# Voice chat
		processMic()
		inputThreshold = AudioVolume.mic_threshold
		
		leahy_dst = global_position.distance_to(get_parent().get_node("EvilLeahy").global_position)
		
		if Input.is_action_just_pressed("debug"):
			pick_item(6)
			pass

		if get_parent().game_started:
			if (10 - leahy_dst) > 0:
				var strength = 1/leahy_dst+0.01
				camera_3d.h_offset = randf_range(-strength,strength) / 5
				camera_3d.v_offset = randf_range(-strength,strength) / 5
			else:
				camera_3d.h_offset = 0
				camera_3d.v_offset = 0
		
		if global_position.z > 15 && !is_freaky:
			if !get_parent().game_started:
				is_freaky = true
				get_parent().skibidi.rpc()
			else:
				global_position.z = 0

		if global_position.y >= 3.727:
			is_on_top = true
		else:
			is_on_top = false
		
		if not is_on_floor() and not is_dead:
			velocity.y -= gravity * delta
		
		$AudioStreamPlayer3D.volume_db = -80

		if Input.is_action_just_pressed("sprint"):
			is_running = true
		elif Input.is_action_just_released("sprint"):
			is_running = false

		if get_parent().canPlayersMove:
			if can_move and not is_suspended:
				if can_cam_move:
					var input_dir = Vector3.ZERO
					input_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
					input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
					
					# Get the forward and right vectors of the character
					var forward = global_transform.basis.z
					var right = global_transform.basis.x
					
					# Calculate the movement direction in global space
					var movement = (forward * input_dir.z + right * input_dir.x).normalized()
					
					if movement != Vector3.ZERO:
						velocity.x = (movement * SPEED).x
						velocity.z = (movement * SPEED).z
						$AudioStreamPlayer3D.volume_db = 0
						is_moving = true
					else:
						velocity.x = velocity.move_toward(Vector3.ZERO, SPEED).x
						velocity.z = velocity.move_toward(Vector3.ZERO, SPEED).z
						is_moving = false
					
					move_and_slide()
					
					# Update is_moving based on actual movement
					if velocity.length() < 0.1:
						is_moving = false
					
					if Input.is_action_just_pressed("interact"):
						if ray.get_collider() != null and get_cur_item() == -1:
							if ray.get_collider().is_in_group("vending_machine"):
								get_parent().use_vending_machine.rpc(name.to_int(),ray.get_collider().name)
							
						if ray.get_collider() != null and get_parent().game_started:
							print(ray.get_collider().name)
							if ray.get_collider().is_in_group("shop"):
								if !get_parent().enable_shop: return
								open_shop()
							if ray.get_collider().name == "CoffeMachine":
								if !get_parent().enable_coffee: return
								if !can_use_coffee: return
								if boosts.has("coffee"):
									boosts["coffee"] += 1
								else:
									boosts["coffee"] = 1
								get_parent().play_coffee.rpc()
								coffee_timeout()
								can_use_coffee = false
								$"Coffee timeout".start(get_parent().coffee_timeout)
							if ray.get_collider().name == "Breaker":
								if !can_use_breaker: return
								if !get_parent().enable_breaker: return
								get_parent().toggle_power.rpc()
								can_use_breaker = false
								$BreakerTimeout.start(get_parent().breaker_timeout)
							if ray.get_collider().name == "Mr_Misuraca":
								open_gambling()
							
							if ray.get_collider().name.begins_with("DroppedItem"):
								var dropped_item = ray.get_collider().item
								if get_cur_item() == -1:
									pick_item(dropped_item)
									get_parent().remove_dropped_item.rpc(ray.get_collider().get_path())
							
							if ray.get_collider().is_in_group("toilet"):
								if !can_toilet_tp : return
								var spawns = get_parent().get_node("Bathroom spawns").get_children()
								
								var farthest_dst = -1
								var farthest_obj
								
								for spawn in spawns:
									if global_position.distance_to(spawn.global_position) > farthest_dst:
										farthest_dst = global_position.distance_to(spawn.global_position)
										farthest_obj = spawn
								can_toilet_tp = false
								$ToiletTimeout.start()
								$"CanvasLayer/Control/cool transition".show()
								$"CanvasLayer/Control/cool transition".play()
								await get_tree().create_timer(0.7).timeout
								global_position = farthest_obj.global_position
								await  get_tree().create_timer(0.7).timeout
								$"CanvasLayer/Control/cool transition".hide()
								play_sound.rpc("res://flush.mp3",5)
							
							if ray.get_collider():
								if ray.get_collider().is_in_group("water fountain"):
									if get_cur_item() == 7:
										$"Hand/Bucket 7/Bucket/water".show()
							if ray.get_collider():
								if ray.get_collider().is_in_group("bucket"):
									if get_cur_item() == -1:
										pick_item(7)
							
					
					if Input.is_action_just_pressed("give"):
						if get_cur_item() == 3:
							var evil_leahy = get_tree().get_first_node_in_group("enemies")
							var distance = global_position.distance_to(evil_leahy.global_position)
							
							var fox = get_tree().get_first_node_in_group("fox")
							var dist = global_position.distance_to(fox.global_position)
							if dist < 20:
								pick_item(-1)
								get_parent().mr_fox_collect.rpc(false)
							elif distance < 15:
								pick_item(-1)
								get_parent().appease_leahy.rpc(steam_name,5)
						elif get_cur_item() == 5:
							var evil_leahy = get_tree().get_first_node_in_group("enemies")
							var distance = global_position.distance_to(evil_leahy.global_position)
							
							var fox = get_tree().get_first_node_in_group("fox")
							var dist = global_position.distance_to(fox.global_position)
							if dist < 30:
								pick_item(-1)
								get_parent().mr_fox_collect.rpc(true)
							elif distance < 30:
								pick_item(-1)
								get_parent().appease_leahy.rpc(steam_name,15)
						elif get_cur_item() == 6:
							var evil_leahy = get_tree().get_first_node_in_group("enemies")
							var distance = global_position.distance_to(evil_leahy.global_position)
							
							if distance < 10:
								pick_item(-1)
								get_parent().boost_leahy.rpc(steam_name)
					
					if Input.is_action_just_pressed("use_item"):
						if get_cur_item() == 0:
							pick_item(-1)
							if boosts.has("fruit snacks"):
								boosts["fruit snacks"] += 1
							else:
								boosts["fruit snacks"] = 1
							fruit_snacks_timeout()
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
						elif get_cur_item() == 6:
							pick_item(-1)
							if boosts.has("redbull"):
								boosts["redbull"] += 2
							else:
								boosts["redbull"] = 2
							redbull_timeout()
							play_sound.rpc("res://redbull.mp3")
						elif get_cur_item() == 7:
							if $"Hand/Bucket 7/Bucket/water".visible:
								$"Hand/Bucket 7/Bucket/water".visible = false
								pick_item(-1)
								play_sound.rpc("res://water.mp3")
								get_parent().spawn_puddle.rpc(Vector3(global_position.x,0,global_position.z))
						
		
		
		
		progress_bar.value = lerp(progress_bar.value, float(stamina), 0.2)
		camera_3d.fov = clamp(lerp(camera_3d.fov, float(cam_fov), 0.1),1,140)
		
		if can_run:
			progress_bar.modulate = Color.WHITE
		else:
			progress_bar.modulate = Color.RED
		
		
		if get_tree():
			for obj: Node3D in get_tree().get_nodes_in_group("localface"):
				obj.look_at(global_position)
				obj.rotation_degrees.x = 0
				obj.rotation_degrees.z = 0

		if Input.is_action_just_pressed("throw"):
			if get_cur_item() != -1:
				var cloned_item = $Hand.get_child(get_cur_item()).get_child(0).get_path()
				get_parent().spawn_dropped_item.rpc($Hand.global_position,cloned_item,get_cur_item())
			
			pick_item(-1)

		if get_parent().leahy_look:
			var target = get_tree().get_nodes_in_group("enemies")[0].global_position

			look_at(target)
			global_rotation_degrees.x = 0
			global_rotation_degrees.z = 0
			
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
		camera_3d.global_transform = $"Camera target".global_transform
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
					rotate_x(deg_to_rad(event.relative.y * -0.3))

func coffee_timeout():
	await get_tree().create_timer(6).timeout
	boosts["coffee"] -= 1

func redbull_timeout():
	await get_tree().create_timer(3).timeout
	boosts["redbull"] -= 2

func toilet_tp_timeout():
	await get_tree().create_timer(60).timeout
	can_toilet_tp = true

var is_in_leahy = false

func _on_area_3d_area_entered(area):
	if !is_multiplayer_authority():
		return
	if is_dead:
		return
	if is_shop_open: return
	print(area.name)
	if area.get_parent().is_in_group("Book"):
		get_parent().on_collect_book.rpc(name.to_int(), area.get_parent().name,true)
		Achievements.books_collected += 1
		Achievements.save_all()
	elif area.get_parent().is_in_group("enemies") and get_parent().game_started == true:
		if get_parent().absent == false:
			if get_parent().is_powered_off == false:
				if get_parent().leahy_appeased == false:
					die("leahy")

	elif area.name == "Landmine" and get_parent().game_started == true:
		die("mine")
		get_parent().on_collect_book.rpc(name.to_int(), area.name,true)
		
	elif area.name == "azzu" and get_parent().azzu_angered == true:
		die("azzu")
		get_parent().azzu_dont_steal.rpc()
	elif area.name == "gainy":
		get_parent().stop_gainy.rpc(name.to_int())
	elif area.name == "puddle":
		if boosts.has("puddle"):
			boosts["puddle"] -= 0.5
		else:
			boosts["puddle"] = 0.5
		$Puddle.start()
	elif area.name == "misuraca":
		if area.get_parent().is_angry == true:
			die("misuraca")
			get_parent().stop_misuraca.rpc()


func _on_timer_timeout():
	if !is_multiplayer_authority():
		return
	
	if is_running and is_moving:
		if stamina > 0:
			if can_run:
				stamina -= 1
				boosts["run"] = 1
		else:
			is_running = false
			can_run = false
			$Stamina_timeout.start()
	else:
		boosts["run"] = 0
		if stamina <= 100:
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
	for i in $Hand.get_children().size():
		set_item_vis.rpc(i,false)
	
	if item != -1:
		set_item_vis.rpc(item,true)
		hand_target_y = 0.3
	else:
		hand_target_y = -0.5
		pass

@rpc("any_peer","call_local")
func set_item_vis(item : int,vis : bool):
	$Hand.get_child(item).visible = vis

func get_cur_item():
	var id = -1
	for i in range(0, $Hand.get_children().size()):
		if $Hand.get_children()[i].visible == true:
			id = i
			break

	return id


@rpc("any_peer", "call_local")
func choose_item(item_ov):
	if item_ov == -1:
		if can_get_item:
			can_get_item = false
			
			var book_multiplier = (get_parent().total_books / get_parent().books_to_collect) * 3
			
			var item_weights = {
				"0":40,
				"1":25,
				"2":20,
				"3":15 + book_multiplier,
				"4":3 ,
				"5":2 + book_multiplier,
				"6":2 + book_multiplier
			}
			
			pick_item(pick_random_weighted(item_weights).to_int())
	else:
		pick_item(item_ov)

func pick_random_weighted(items_chances: Dictionary) -> Variant:
	# Calculate the total weight
	var total_weight = 0.0
	for weight in items_chances.values():
		total_weight += weight
	
	# Pick a random value within the range of total_weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	# Iterate through the dictionary to find the item
	for item in items_chances.keys():
		cumulative_weight += items_chances[item]
		if random_value <= cumulative_weight:
			return item
	
	# Fallback in case of rounding errors
	return items_chances.keys()[-1]

func fruit_snacks_timeout():
	await get_tree().create_timer(3).timeout
	boosts["fruit snacks"] -= 1

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

@rpc("any_peer","call_local")
func die(cause):
	if is_dead: return
	$visual_body.global_rotation_degrees.x = 0
	can_move = false
	if cause == "mine":
		if get_parent().landmine_death:
			get_parent().set_player_dead.rpc(name.to_int(), true,true)
		else:
			get_parent().set_player_dead.rpc(name.to_int(), true,false)
	else:
		get_parent().set_player_dead.rpc(name.to_int(), true,true)
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
	close_shop(false)
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
	elif cause == "misuraca":
		$"CanvasLayer/Control/Died thing/jumpscare7".play()

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

var is_shop_open = false

func open_shop():
	if can_use_shop:
		is_minimap_open = false
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
		is_shop_open = true

func close_shop(set_death = true):
	$CanvasLayer/Control/Shop.hide()
	$CanvasLayer/Control/Shop/AudioStreamPlayer.stop()
	can_cam_move = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioServer.set_bus_solo(6,false)
	if set_death:
		get_parent().set_player_dead.rpc(name.to_int(), false,false)
	$"CanvasLayer/Control/Shop/shop timer".stop()
	is_shop_open = false
	

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
	for i in range(0,4):
		if i != right_choice:
			item_list.add_item(str(ans + randi_range(-5,5)))
		else:
			
			right_ans_index = item_list.add_item(str(ans))

func _on_item_list_item_clicked(index, _at_position, _mouse_button_index):

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


func _on_breaker_timeout_timeout():
	can_use_breaker = true


func _on_coffee_timeout_timeout():
	can_use_coffee = true

@rpc("any_peer","call_local")
func play_sound(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20):
	var a = AudioStreamPlayer3D.new()
	a.stream = load(stream_path)
	a.bus = bus
	a.max_distance = max_distance
	a.volume_db = volume_db
	get_parent().add_child(a)
	a.global_position = global_position
	a.play()

var is_minimap_open = false
@onready var minimap_zoom = minimap_cam.size

func _unhandled_input(event):
	if is_minimap_open:
		if event.is_action_pressed("zoom_in"):
				minimap_zoom -= 3
		if event.is_action_pressed("zoom_out"):
				minimap_zoom += 3

var dragging = false
var last_mouse_position


func _on_texture_rect_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				# Start dragging
				dragging = true
				last_mouse_position = event.position
			else:
				# Stop dragging
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		# Calculate the drag offset
		var drag_offset = event.position - last_mouse_position
		
		# Define a minimum zoom factor to avoid division by zero or too small values
		var min_zoom_factor = 0.1
		
		# Calculate the zoom factor such that it increases with zoom in
		var zoom_factor = max(min_zoom_factor, minimap_zoom / 500.0)
		
		# Adjust the drag offset based on the zoom factor
		var adjusted_drag_offset = drag_offset * zoom_factor
		
		# Update the position of the target object
		$Minimap/Camera3D.global_position.x -= adjusted_drag_offset.x
		$Minimap/Camera3D.global_position.z -= adjusted_drag_offset.y
		#target_object.position += drag_offset
		# Update the last mouse position
		last_mouse_position = event.position



func _on_stamina_flash_timeout():
	if !can_run:
		progress_bar_handler.visible = !progress_bar_handler.visible
	else:
		progress_bar_handler.visible = true

func control_text_setters():
	var looking_at = ray.get_collider()
	
	var final_text = ""
	if looking_at:
		if looking_at.is_in_group("vending_machine"):
			if get_cur_item() == -1:
				final_text += "Vending Machine\nE - grab item"
			else:
				final_text += "Vending Machine\nYou already have an item"
		if looking_at.name == "CoffeMachine":
			final_text += "Coffee Machine\n" + format_time("Coffee timeout","E - drink")
		if looking_at.is_in_group("shop"):
			final_text += "The Shop\n" + format_time("ShopTimeout","E - open the shop")
		if looking_at.name == "Breaker":
			final_text += "The Breaker\n" + format_time("BreakerTimeout","E - turn off power")
		if looking_at.is_in_group("toilet"):
			final_text += "Toilet\n" + format_time("ToiletTimeout","E - flush down")
		if looking_at.name == "water fountain":
			if get_cur_item() != 7:
				final_text += "Water fountain\nGet a bucket to fill it"
			else:
				if !$"Hand/Bucket 7/Bucket/water".visible:
					final_text += "Water fountain\nE - fill the bucket"
				else:
					final_text += "Water fountain\nBucket is full"
		if looking_at.name == "Mr_Misuraca":
			final_text += "Mr.Misuraca\nE - Make a bet"
	
	var cur_item = get_cur_item()
	if final_text != "":
		final_text += "\n"
	
	if cur_item == 0:
		final_text += "Fruit Snacks\nRight Click - Eat"
	elif cur_item == 1:
		final_text += "Clorox Wipes\nRight Click - Launch"
	elif cur_item == 2:
		final_text += "Square Pizza\nRight Click - Eat"
	elif cur_item == 3 or cur_item == 5:
		final_text += "Mtn Dew\nLeft Click - Give to a teacher"
	elif cur_item == 4:
		final_text += "Duck\nRight Click - Squeak"
	elif cur_item == 6:
		final_text += "Redbull\nLeft Click - Give to Ms.Leahy\nRight Click - Drink"
	elif cur_item == 7:
		if $"Hand/Bucket 7/Bucket/water".visible:
			final_text += "Bucket\nRight Click - Pour water out"
		else:
			final_text += "Bucket\nFill the bucket to use it"
	
	controls_text.text = final_text

func format_time(timer_path,succes_string):
	var time_left = floor(get_node(timer_path).time_left)
	if time_left > 0:
		return str(time_left) + "s until available"
	else:
		return succes_string


func _on_toilet_timeout_timeout():
	can_toilet_tp = true


func _on_puddle_timeout():
	boosts["puddle"] = 0

var gamble = []

func open_gambling():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	can_cam_move = false
	$CanvasLayer/Control/paper.show()
	gamble = []
	
	for i in range(0,3):
		var g = {
			"books": randi_range(1,5),
			"time": randi_range(90,240),
			"reward": randi_range(3,6),
			"loss": randi_range(1,3)
		}
		gamble.append(g)
		
		$CanvasLayer/Control/paper.get_node(NodePath("gamble" + str(i + 1))).text = "if you get %s notebooks in %s seconds, i will give everyone a %s. If you don't, i will take %s books." % [g.books,g.time,$Hand.get_child(g.reward).name,g.loss]
		get_parent().set_player_dead.rpc(name.to_int(), true,false)

func close_gambling():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	can_cam_move = true
	$CanvasLayer/Control/paper.hide()
	get_parent().set_player_dead.rpc(name.to_int(), false,false)


func _on_gamblebtn_1_pressed():
	get_parent().do_bet.rpc(steam_name,gamble[0].books,gamble[0].time,gamble[0].loss,gamble[0].reward,$Hand.get_child(gamble[0].reward).name)
	close_gambling()


func _on_gamblebtn_2_pressed():
	get_parent().do_bet.rpc(steam_name,gamble[1].books,gamble[1].time,gamble[1].loss,gamble[1].reward,$Hand.get_child(gamble[1].reward).name)
	close_gambling()


func _on_gamblebtn_3_pressed():
	get_parent().do_bet.rpc(steam_name,gamble[2].books,gamble[2].time,gamble[2].loss,gamble[2].reward,$Hand.get_child(gamble[2].reward).name)
	close_gambling()
