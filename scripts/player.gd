extends CharacterBody3D

const OG_SPEED = 6.0
var SPEED = OG_SPEED
var boosts = {}
var is_boosted = false

const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var books_collected = 0

var is_running = false
var stamina = 100
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

var is_suspended = false


var is_on_top = false
var on_top_counter = 0

@onready var default = $visual_body/Default
@onready var perfect = $visual_body/Perfect
@onready var impossible = $visual_body/Impossible
@onready var freaky = $visual_body/Freaky

var can_get_item = true

@onready var camera_3d = $Camera3D
@onready var minimap_cam = $Minimap/Camera3D

var leahy_dst = 0


var credits = 0
var can_use_shop = true

@onready var controls_text = get_parent().controls_text

var parent = null

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	if !Allsingleton.non_steam:
		$nametag.text = Steam.getPersonaName()
		steam_name = Steam.getPersonaName()
	else:
		$nametag.text = OS.get_environment("USERNAME")
		steam_name = OS.get_environment("USERNAME")
	parent = get_parent()
	
	if is_multiplayer_authority():
		$CanvasLayer.show()
		parent.hide_menu()
		

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_multiplayer_authority():
		
		if Allsingleton.is_bossfight:
			$"CanvasLayer/Control/Progress bar handler/ProgressBar".hide()
		
		# Store the original position and rotation of the hand
		original_rotation = $Hand.rotation_degrees
		
		$visual_body.hide()
		
		var skins = $visual_body.get_children()
		for skin in skins:
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
	
		if Settings.render_distance:
			camera_3d.far = Settings.render_distance
		
		GuiManager.show_tip_once("movement_controls","[color=green]Movement[/color]\nWASD to move, LeftShift to run (consumes stamina), Space to look behind, M to open the minimap")

var is_freaky = false
var can_use_breaker = true
var can_use_coffee = true

var hand_target_y = -0.5
var can_toilet_tp = true

const push_force = 1.0

func _physics_process(delta):
	if is_multiplayer_authority():
		
		if global_position.distance_to(get_tree().get_first_node_in_group("evil darel").global_position) < 1:
			die("darel")
		
		if Input.is_action_just_pressed("revive"):
			if is_dead_of_dariel:
				_on_revive_timer_timeout()
		
		if Input.is_action_just_pressed("punch"):
			punch()
		
		arm_sway(delta)
		
		update_item_weights()
		
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			var collider = collision.get_collider()
			
			# If the collider is a RigidBody
			if collider is RigidBody3D:
				# Calculate the push direction
				var push_direction = collision.get_normal()
				
				# Apply the force to the RigidBody
				collider.push_item.rpc(push_direction,push_force)
				
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
		if !parent.leahy_look:
			if final_multiplier != 1:
				cam_fov = 75 + final_multiplier * 15
			else:
				cam_fov = 75
		$Hand.position.y = lerp($Hand.position.y,hand_target_y,0.25)
		
		$CanvasLayer/Control/Shop/ColorRect/timer.text = str(floor($"CanvasLayer/Control/Shop/shop timer".time_left)) + "s left"
		
		$CanvasLayer/Control/Shop/ColorRect/Label2.text = str(credits) + " credits"
		
		leahy_dst = global_position.distance_to(Game.get_closest_node_in_group(global_position,"evil_leahy").global_position)
		
		if Input.is_action_just_pressed("debug"):
			parent.on_collect_book.rpc(name.to_int(), "book1",true)

		if Game.game_started:
			if (10 - leahy_dst) > 0:
				var strength = 1/leahy_dst+0.01
				camera_3d.h_offset = randf_range(-strength,strength) / 5
				camera_3d.v_offset = randf_range(-strength,strength) / 5
			else:
				camera_3d.h_offset = 0
				camera_3d.v_offset = 0
		
		if global_position.z > 15 && !is_freaky:
			if !Game.game_started:
				is_freaky = true
				parent.skibidi.rpc()
			else:
				global_position.z = 0
		
		movement_function(delta)
		
		progress_bar.value = lerp(progress_bar.value, float(stamina), 0.2)
		camera_3d.fov = clamp(lerp(camera_3d.fov, float(cam_fov), 0.1),1,140)
		
		
		camera_3d.current = true
		camera_3d.global_transform = $"Camera target".global_transform

func punch():
	
	if ray.get_collider():
		var collider = ray.get_collider()
		print("PARRY:",collider.name)
		
		if Allsingleton.is_bossfight:
			if collider.is_in_group("lil darel"):
				
				$VisualHand/AnimationPlayer.play("parry")
				collider.inverse = true
				collider.is_stopped = true
				await Game.sleep(0.15)
				$"Parry sound".play()
				
				parry_pause(collider)
				$CanvasLayer/Control/parry.show()
				get_tree().paused = true
			elif collider.is_in_group("evil_wipes"):
				$VisualHand/AnimationPlayer.play("parry")
				collider.reversed = true
				collider.is_evil = false
				collider.is_stopped = true
				await Game.sleep(0.15)
				$"Parry sound".play()
				
				parry_pause(collider)
				$CanvasLayer/Control/parry.show()
				get_tree().paused = true
			
		else:
			$VisualHand/AnimationPlayer.play("punch")
	else:
		$VisualHand/AnimationPlayer.play("punch")

func parry_pause(collider):
	await Game.sleep(0.25)
	get_tree().paused = false
	
	if is_instance_valid(collider):
		if collider.is_in_group("lil darel") or collider.is_in_group("evil_wipes"):
			collider.is_stopped = false
	
	$CanvasLayer/Control/parry.hide()
	

var vertical_angle = 0.0
var max_vertical_angle = 89.0  # You can adjust this as needed.

func _input(event):
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		if can_move:
			if can_cam_move:
				rotate_y(deg_to_rad(event.relative.x * -0.3))
				if parent.do_vertical_camera:
					# funni
					rotate_x(deg_to_rad(event.relative.y * -0.3))
				
				if parent.do_vertical_camera_normal:
					# Calculate new vertical angle
					vertical_angle -= event.relative.y * 0.3
					vertical_angle = clamp(vertical_angle, -max_vertical_angle, max_vertical_angle)
	
					# Set the new rotation by using Euler angles
					rotation.x = deg_to_rad(vertical_angle)
	
	if event is InputEventKey:
		if OS.has_feature("debug"):
			if event.pressed:
				var regex = RegEx.new() # Create a new RegEx object
				var pattern = "^[0-9]+$" # Pattern to allow only numbers from 0-9
				regex.compile(pattern) # Compile the pattern
				
				if regex.search(event.as_text_keycode()):
					pick_item(event.as_text_keycode().to_int())
	

func coffee_timeout():
	await Game.sleep(6)
	boosts["coffee"] -= 1

func redbull_timeout():
	await Game.sleep(3)
	boosts["redbull"] -= 2

func toilet_tp_timeout():
	await Game.sleep(60)
	can_toilet_tp = true

func baja_timeout():
	await Game.sleep(7.5)
	boosts["baja"] -= 4.5
	baja_slow_timeout()
	
func sonic_timeout():
	await Game.sleep(5)
	boosts["sonic"] -= 3

func baja_slow_timeout():
	await Game.sleep(15)
	boosts["baja"] += 0.5

var is_in_leahy = false

func _on_area_3d_area_entered(area):
	if !is_multiplayer_authority():
		return
	if is_dead:
		return
	if is_shop_open: return
	print(area.name)
	if area.get_parent().is_in_group("Book"):
		parent.on_collect_book.rpc(name.to_int(), area.get_parent().name,true)
		Achievements.books_collected += 1
		Achievements.save_all()
	elif area.get_parent().is_in_group("evil_leahy") and Game.game_started == true:
		var evil_leahy = area.get_parent()
		
		if evil_leahy.absent == false:
			if Game.powered_off == false:
				if evil_leahy.appeased == false:
					if evil_leahy.baja_blasted == false:
						die("leahy")

	elif area.name == "Landmine" and Game.game_started == true:
		die("mine")
		parent.on_collect_book.rpc(name.to_int(), area.name,true)
		
	elif area.name == "azzu":
		if area.get_parent().angered:
			die("azzu")
	elif area.name == "gainy":
		if area.get_parent().angered:
			die("gainy")
	elif area.name == "puddle":
		if !area.get_parent().can_slowdown: return
		if boosts.has("puddle"):
			boosts["puddle"] -= 0.5
		else:
			boosts["puddle"] = 0.5
		$Puddle.start()
	elif area.name == "misuraca":
		if area.get_parent().is_angry == true:
			die("misuraca")
	elif area.name == "Door":
		area.get_parent().set_open.rpc(true)
		play_sound("res://door_open.mp3")
		
	elif area.is_in_group("pacer target"):
		parent.check_if_finished_pacer_lap.rpc(name,area.get_path())
	elif area.name == "darel ball":
		die("darel")
		area.get_parent().queue_free()

func _on_area_3d_area_exited(area):
	if !is_multiplayer_authority(): return
	if is_dead: return
	if is_shop_open: return
	
	if area.name == "Door":
		area.get_parent().set_open.rpc(false)
		play_sound("res://door_close.mp3")


func _on_timer_timeout():
	if !is_multiplayer_authority():
		return
	
	if is_running and is_moving:
		if stamina > 0:
			if can_run:
				if !Allsingleton.is_bossfight:
					stamina -= 1
				boosts["run"] = 1
		else:
			is_running = false
			can_run = false
			$Stamina_timeout.start()
			GuiManager.show_tip_once("stamina_timeout","[color=green]Stamina[/color]\nIf stamina [b]reaches 0[/b], you will not be able to run for a few seconds.")
			
	else:
		boosts["run"] = 0
		if stamina <= 100:
			stamina += 1
	
	


func _on_stamina_timeout_timeout():
	if !is_multiplayer_authority():
		return
	can_run = true


func _on_revive_timer_timeout():
	if !is_multiplayer_authority(): return
	if not is_suspended:
		global_position = get_tree().get_nodes_in_group("player_spawn").pick_random().global_position
		parent.set_player_dead.rpc(name.to_int(), false,false)
	else:
		global_position = Vector3(45, 1.2, -43)
		parent.set_player_dead.rpc(name.to_int(), true,false)
	$"CanvasLayer/Control/Died thing".hide()
	AudioServer.set_bus_mute(1, false)
	AudioServer.set_bus_mute(2, false)
	is_dead = false
	$visual_body.global_rotation_degrees.x = 0
	can_move = true
	$CollisionShape3D.disabled = false
	close_gambling(false)
	
	$"CanvasLayer/Control/Died thing/darel death".hide()
	$"CanvasLayer/Control/Died thing/darel death/AnimationPlayer".stop()
	is_dead_of_dariel = false
	$"CanvasLayer/Control/Died thing/darel death/AudioStreamPlayer2".stop()
	
	if death_cause == "mine":
		GuiManager.show_tip_once("landmine","[color=green]Bananas[/color]\nDo [b]NOT[/b] add to the death counter in a normal game. Be careful!")
	elif death_cause == "azzu" or death_cause == "misuraca":
		GuiManager.show_tip_once("clorox_teachers","[color=green]Teachers and Clorox[/color]\nSome people just don't like to get pushed i guess, just [b]don't use a clorox wipe[/b] near or on them.")
	elif death_cause == "wall":
		GuiManager.show_tip_once("wall_death","[color=green]Walking on walls[/color]\nDo [b]NOT[/b] do that.")
	elif death_cause == "freezer":
		GuiManager.show_tip_once("freezer_death","[color=green]Freezer[/color]\n Don't stay in the freezer for too long! You will freeze to [color=red]death[/color].")
func pick_item(item: int):
	
	for i in $Hand.get_children().size():
		set_item_vis.rpc(i,false)
	
	if item != -1:
		set_item_vis.rpc(item,true)
		hand_target_y = 0.3
		GuiManager.show_tip_once("items","[color=green]Items[/color]\nEvery item can be used by clicking [b]either right or left[/b] mouse button. [b]Press Q[/b] to throw the item out.")
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

var item_weights = {}

func update_item_weights():
	var book_multiplier = (parent.total_books / parent.books_to_collect) * 3
	item_weights = {
		"0":25, # Fruit Snacks
		"1":20, # Clorox
		"2":20, # Pizza
		"3":15 + book_multiplier, # Mtn Dew
		"4":3, # Duck
		"5":2 + book_multiplier, # Sunkist
		"6":2 + book_multiplier, # Redbull
		"8":1 + book_multiplier, # Baja Blast
		"10": 0.1 # Sonic gummies
	}

@rpc("any_peer", "call_local")
func choose_item(item_ov,ov_timeout = false):
	if item_ov == -1:
		if can_get_item:
			can_get_item = false
			
			pick_item(pick_random_weighted(item_weights).to_int())
	else:
		if ov_timeout:
			if !can_get_item: return
			can_get_item = false
		
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
	await Game.sleep(3)
	boosts["fruit snacks"] -= 1

@rpc("any_peer", "call_local")
func spawn_clorox():
	var packed_clorox = load("res://Clorox Wipes.tscn")
	var clorox: StaticBody3D = packed_clorox.instantiate()

	get_parent().add_child(clorox)

	clorox.initial_pos = $RayCast3D.global_position
	clorox.global_position = $RayCast3D.global_position
	clorox.global_rotation = $"Camera target".global_rotation
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

var is_dead_of_dariel = false

var death_cause = ""

@rpc("any_peer","call_local")
func die(cause):
	if is_dead: return
	
	$visual_body.global_rotation_degrees.x = 0
	can_move = false
	if cause == "mine":
		if parent.landmine_death:
			parent.set_player_dead.rpc(name.to_int(), true,true)
		else:
			parent.set_player_dead.rpc(name.to_int(), true,false)
	else:
		parent.set_player_dead.rpc(name.to_int(), true,true)
	$"CanvasLayer/Control/Died thing".show()
	if cause != "darel":
		$ReviveTimer.start(parent.death_timeout)
	is_dead = true
	AudioServer.set_bus_mute(1, true)
	AudioServer.set_bus_mute(2, true)
	$"CanvasLayer/Control/Died thing/AudioStreamPlayer".play()
	#TODO: make this work $CollisionShape3D.disabled = true
	Achievements.deaths += 1
	Achievements.save_all()
	$CanvasLayer/Control/Control.hide()
	close_shop(false)
	
	death_cause = cause
	
	if cause == "leahy":
		$"CanvasLayer/Control/Died thing/jumpscare".play()
		if parent.do_silent_lunch:
			var chance = randi_range(0, 2)
			if chance == 0:
				$CanvasLayer/Control/silentLunch.show()
				$CanvasLayer/Control/silentLunch.text = "You got silent lunch\nyou can leave in " + str(parent.silent_lunch_duration)
				is_suspended = true
				$"Silent Lunch".start(parent.silent_lunch_duration)

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
	elif cause == "darel":
		$"CanvasLayer/Control/Died thing/darel death".show()
		$"CanvasLayer/Control/Died thing/darel death/AnimationPlayer".play("ha")
		is_dead_of_dariel = true
		get_tree().get_first_node_in_group("evil darel").health = 100
		$"CanvasLayer/Control/Died thing/darel death/AudioStreamPlayer2".play()
		$"CanvasLayer/Control/Died thing/darel death/AnimationPlayer2".play("textfadein")
		
		for lil_darel in get_tree().get_nodes_in_group("lil darel"):
			lil_darel.queue_free()
		

func _on_silent_lunch_timeout():
	is_suspended = false
	parent.set_player_dead.rpc(name.to_int(), false,false)
	$CanvasLayer/Control/silentLunch.hide()


func _on_anti_wall_walk_timeout():
	if is_on_top:
		on_top_counter += 1
		if on_top_counter == 10:
			if !Allsingleton.is_bossfight:
				die("wall")
				global_position.y = 1
			on_top_counter = 0
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
		parent.set_player_dead.rpc(name.to_int(), true,false)
		can_use_shop = false
		$ShopTimeout.start(parent.shop_timeout)
		parent.shop.hide()
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
		parent.set_player_dead.rpc(name.to_int(), false,false)
	$"CanvasLayer/Control/Shop/shop timer".stop()
	is_shop_open = false
	

func _on_shop_timeout_timeout():
	can_use_shop = true
	parent.shop.show()

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
	var is_right_there = false
	
	for i in range(0,4):
		if i != right_choice:
			var rand_change = null
			
			if randi_range(0,1) == 0:
				rand_change = randi_range(-10,-1)
			else:
				rand_change = randi_range(10,1)
			
			item_list.add_item(str(ans + rand_change))
		else:
			right_ans_index = item_list.add_item(str(ans))
			is_right_there = true
	
	
	
	if is_right_there == false:
		print("answer not here. skipping")
		generate_show_question()

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
		parent.on_collect_book.rpc(name.to_int(), "book1",true)
		Achievements.books_collected += 1
		Achievements.save_all()
		
		play_sound("res://money.mp3")

func _on_buy_duck_pressed():
	if credits >= 10:
		credits -= 10
		close_shop()
		pick_item(4)
		
		play_sound("res://money.mp3")

func _on_buy_baja_pressed():
	if credits >= 15:
		credits -= 15
		close_shop()
		pick_item(8)
		
		play_sound("res://money.mp3")


func _on_breaker_timeout_timeout():
	can_use_breaker = true


func _on_coffee_timeout_timeout():
	can_use_coffee = true

func play_sound(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20):
	parent.play_sound.rpc(stream_path,volume_db,bus,max_distance,global_position)


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

# INFOTEXT

func control_text_setters():
	var looking_at = ray.get_collider()
	
	var final_text = ""
	if looking_at:
		if looking_at.is_in_group("vending_machine"):
			if get_cur_item() == -1:
				final_text += "Vending Machine\nE - grab item"
			else:
				final_text += "Vending Machine\nYou already have an item"
		elif looking_at.name == "CoffeMachine":
			final_text += "Coffee Machine\n" + format_time("Coffee timeout","E - drink")
		elif looking_at.is_in_group("shop"):
			final_text += "The Shop\n" + format_time("ShopTimeout","E - open the shop")
		elif looking_at.name == "Breaker":
			final_text += "The Breaker\n" + format_time("BreakerTimeout","E - turn off power")
		elif looking_at.is_in_group("toilet"):
			final_text += "Toilet\n" + format_time("ToiletTimeout","E - flush down")
		elif looking_at.name == "water fountain":
			if get_cur_item() != 7:
				final_text += "Water fountain\nGet a bucket to fill it"
			else:
				if !$"Hand/Bucket 7/Bucket/water".visible:
					final_text += "Water fountain\nE - fill the bucket"
				else:
					final_text += "Water fountain\nBucket is full"
		elif looking_at.name == "Mr_Misuraca":
			final_text += "Mr.Misuraca\nE - Make a bet"
		elif looking_at.name == "thej":
			final_text += "Projector\n E - play"
		elif looking_at.name == "wheel":
			final_text += "Wheel\n E - Spin"
		elif looking_at.is_in_group("fence"):
			final_text += "Wheel\n You need more notebooks to spin it!"
		elif looking_at.is_in_group("freezer"):
			final_text += "Freezer\n E - Get inside"
	
	var cur_item = get_cur_item()
	if final_text != "":
		final_text += "\n"
	
	if cur_item == 0:
		final_text += "Fruit Snacks\nRight Click - Eat"
		GuiManager.show_tip_once("fruit_snacks","[color=green]Fruit Snacks[/color]\nWhen eaten, will give you a [b]2x speed boost[/b] for a few seconds.")
	elif cur_item == 1:
		final_text += "Clorox Wipes\nRight Click - Launch"
		GuiManager.show_tip_once("clorox_wipes","[color=green]Clorox wipes[/color]\nWhen used, will [b]launch a clorox wipe[/b] in the direction you are looking at. It will [b]push everything[/b] along the way.",10)
	elif cur_item == 2:
		final_text += "Square Pizza\nRight Click - Eat"
		GuiManager.show_tip_once("pizza","[color=green]Square pizza[/color]\nWhen eaten, you shart and jump. That's it.")
	elif cur_item == 3:
		final_text += "Mtn Dew\nLeft Click - Give to a teacher"
		GuiManager.show_tip_once("mtn_dew","[color=green]Mtn Dew[/color]\nWhen given to Ms.Leahy, she [b]gets stunned[/b] for 5 secodns. When given to Mr.Fox, he will [b]go to the notebook.[/b]",10)
	elif cur_item == 4:
		final_text += "Duck\nRight Click - Squeak"
		GuiManager.show_tip_once("duck_item","[color=green]Duck[/color]\n\nno.")
	elif cur_item == 5:
		final_text += "Sunkist Orange\nLeft Click - Give to a teacher"
		GuiManager.show_tip_once("sunkist","[color=green]Sunkist Orange[/color]\nWhen given to Ms.Leahy, she [b]gets stunned[/b] for 15 secodns. When given to Mr.Fox, he will [b]go to 2 notebooks.[/b]",10)
	elif cur_item == 6:
		final_text += "Redbull\nLeft Click - Give to Ms.Leahy\nRight Click - Drink"
		GuiManager.show_tip_once("redbull","[color=green]Redbull[/color]\nJust [b]don't[/b] give it to Ms.Leahy please.")
	elif cur_item == 7:
		if $"Hand/Bucket 7/Bucket/water".visible:
			final_text += "Bucket\nRight Click - Pour water out"
		else:
			final_text += "Bucket\nFill the bucket to use it"
		GuiManager.show_tip_once("bucket_item","[color=green]Bucket[/color]\nCan be filled up using a [b]water fountain[/b]. When it's full, can be used to make a [b]puddle[/b] that will [b]slow Ms.Leahy[/b] down",10)
	elif cur_item == 8:
		final_text += "Baja Blast\nRight Click - Drink\nLeft Click - Give to Ms.Leahy"
		GuiManager.show_tip_once("baja_blast","[color=green]Baja Blast[/color]\nWhen drinked, gives you a huge speedboost for a few seconds, but you get [b]withdrawals[/b]. Same with [b]Ms.Leahy[/b]")
	elif cur_item == 9:
		final_text += "Fire Extinguisher\n Right Click - Use"
		GuiManager.show_tip_once("fire_ext","[color=green]Fire Extinguisher[/color]\nWhen used, will make a little [b]smoke cloud[/b], that [b]no one can pass through[/b]")
	elif cur_item == 10:
		final_text += "Sonic Gummies\n Right Click - Eat"
		GuiManager.show_tip_once("sonic_gummies","[color=green]Sonnic gummies[/color]\nWhen eaten, will give you a [b]speed boost[/b] for a few seconds.")
		
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

# GAMBLING

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
		parent.set_player_dead.rpc(name.to_int(), true,false)

func close_gambling(do_deaths = true):
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	can_cam_move = true
	$CanvasLayer/Control/paper.hide()
	if do_deaths:
		parent.set_player_dead.rpc(name.to_int(), false,false)


func _on_gamblebtn_1_pressed():
	parent.do_bet.rpc(steam_name,gamble[0].books,gamble[0].time,gamble[0].loss,gamble[0].reward,$Hand.get_child(gamble[0].reward).name)
	close_gambling()


func _on_gamblebtn_2_pressed():
	parent.do_bet.rpc(steam_name,gamble[1].books,gamble[1].time,gamble[1].loss,gamble[1].reward,$Hand.get_child(gamble[1].reward).name)
	close_gambling()


func _on_gamblebtn_3_pressed():
	parent.do_bet.rpc(steam_name,gamble[2].books,gamble[2].time,gamble[2].loss,gamble[2].reward,$Hand.get_child(gamble[2].reward).name)
	close_gambling()



# MOVEMENT

var is_in_freezer = false

func movement_function(delta):
	
	if global_position.y >= 3.727:
			is_on_top = true
	else:
			is_on_top = false
	
	if Allsingleton.is_bossfight:
		if Game.game_started:
			if is_on_floor() and not is_dead:
				if Input.is_action_just_pressed("jump"):
					velocity.y += 5
	else:
		if Input.is_action_pressed("jump"):
			$"Camera target".rotation_degrees.y = 180
		else:
			$"Camera target".rotation_degrees.y = 0
	
	if not is_on_floor() and not is_dead:
		velocity.y -= gravity * delta
		
		
	if Input.is_action_just_pressed("sprint"):
		is_running = true
	elif Input.is_action_just_released("sprint"):
		is_running = false
	
	$AudioStreamPlayer3D.volume_db = -80
	
	if can_run:
		progress_bar.modulate = Color.WHITE
	else:
		progress_bar.modulate = Color.RED
	
	if Input.is_action_just_pressed("jump"):
		if is_in_freezer:
			can_move = true
			is_in_freezer = false
			parent.set_player_dead.rpc(name.to_int(), false,false)
			$CanvasLayer/Control/Freezer/AnimationPlayer.play("RESET")
			$freezerDeath.stop()
	
	if parent.canPlayersMove:
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
						if ray.get_collider().is_in_group("vending_machines"):
							choose_item(-1)
							ray.get_collider().use_vending_machine.rpc()
						
					if ray.get_collider() != null and Game.game_started:
						print(ray.get_collider().name)
						if ray.get_collider().is_in_group("shop"):
							if !parent.enable_shop: return
							open_shop()
						if ray.get_collider().name == "CoffeMachine":
							if !parent.enable_coffee: return
							if !can_use_coffee: return
							if boosts.has("coffee"):
								boosts["coffee"] += 1
							else:
								boosts["coffee"] = 1
							parent.play_coffee.rpc()
							coffee_timeout()
							can_use_coffee = false
							$"Coffee timeout".start(parent.coffee_timeout)
						if ray.get_collider().name == "Breaker":
							if !can_use_breaker: return
							if !parent.enable_breaker: return
							parent.toggle_power.rpc()
							can_use_breaker = false
							$BreakerTimeout.start(parent.breaker_timeout)
						if ray.get_collider().name == "Mr_Misuraca":
							open_gambling()
						
						if ray.get_collider().name.begins_with("DroppedItem"):
							var dropped_item = ray.get_collider().item
							if get_cur_item() == -1:
								pick_item(dropped_item)
								parent.remove_dropped_item.rpc(ray.get_collider().get_path())
						
						if ray.get_collider().name == "thej":
							parent.play_the_j.rpc()
						if ray.get_collider().name == "fire":
							ray.get_collider().get_parent().break_glass.rpc()
							if ray.get_collider().get_parent().can_pickup:
								pick_item(9)
						if ray.get_collider().name == "wheel":
							ray.get_collider().get_parent().spin.rpc()
						if ray.get_collider().is_in_group("freezer"):
							global_position.x = ray.get_collider().global_position.x
							global_position.z = ray.get_collider().global_position.z
							can_move = false
							global_rotation.y = -ray.get_collider().global_rotation.y
							parent.set_player_dead.rpc(name.to_int(), true,false)
							is_in_freezer = true
							$CanvasLayer/Control/Freezer/AnimationPlayer.play("freez")
							
							$freezerDeath.start()
							
								
							
						
						if ray.get_collider().is_in_group("toilet"):
							if !can_toilet_tp : return
							var spawns = parent.get_node("School/Bathroom spawns").get_children()
							
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
							await Game.sleep(0.7)
							global_position = farthest_obj.global_position
							await Game.sleep(0.7)
							$"CanvasLayer/Control/cool transition".hide()
							play_sound("res://flush.mp3",5)
						
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
						var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
						var distance = global_position.distance_to(evil_leahy.global_position)
						
						var fox = Game.get_closest_node_in_group(global_position,"mr_fox")
						var dist = global_position.distance_to(fox.global_position)
						if dist < 20:
							pick_item(-1)
							
							parent.mr_fox_collect.rpc(false)
						elif distance < 15:
							pick_item(-1)
							
							evil_leahy.appease.rpc(steam_name,5)
					elif get_cur_item() == 5:
						var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
						var distance = global_position.distance_to(evil_leahy.global_position)
						
						var fox = Game.get_closest_node_in_group(global_position,"mr_fox")
						var dist = global_position.distance_to(fox.global_position)
						if dist < 30:
							pick_item(-1)
							parent.mr_fox_collect.rpc(true)
						elif distance < 30:
							pick_item(-1)
							evil_leahy.appease.rpc(steam_name,15)
						
					elif get_cur_item() == 6:
						var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
						var distance = global_position.distance_to(evil_leahy.global_position)
						
						if distance < 10:
							pick_item(-1)
							parent.boost_leahy.rpc(steam_name)
					elif get_cur_item() == 8:
						var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
						var distance = global_position.distance_to(evil_leahy.global_position)
						
						if distance < 10:
							pick_item(-1)
							evil_leahy.baja_blast_her.rpc(steam_name)
				
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
						parent.start_da_pacer.rpc(name.to_int()) # i want to kms because of this
					elif get_cur_item() == 6:
						pick_item(-1)
						if boosts.has("redbull"):
							boosts["redbull"] += 2
						else:
							boosts["redbull"] = 2
						redbull_timeout()
						play_sound("res://redbull.mp3")
					elif get_cur_item() == 7:
						if $"Hand/Bucket 7/Bucket/water".visible:
							$"Hand/Bucket 7/Bucket/water".visible = false
							pick_item(-1)
							play_sound("res://water.mp3")
							parent.spawn_puddle.rpc(Vector3(global_position.x,0,global_position.z))
					elif get_cur_item() == 8:
						pick_item(-1)
						is_baja = true
						
						if boosts.has("baja"):
							boosts["baja"] += 4
						else:
							boosts["baja"] = 4
						baja_timeout()
						$"baja trail".start()
					elif get_cur_item() == 9:
						pick_item(-1)
						parent.spawn_smoke.rpc(global_position)
						play_sound("res://fire extinguisher.mp3")
					elif get_cur_item() == 10:
						pick_item(-1)
						if boosts.has("sonic"):
							boosts["sonic"] += 3
						else:
							boosts["sonic"] = 3
						sonic_timeout()
						play_sound("res://models/sonic.mp3",3)

	if Input.is_action_just_pressed("throw"):
		if get_cur_item() != -1:
			var cloned_item = $Hand.get_child(get_cur_item()).get_child(0).get_path()
			parent.spawn_dropped_item.rpc($Hand.global_position,cloned_item,get_cur_item())
		
		pick_item(-1)
	if parent.leahy_look:
		var target = get_tree().get_nodes_in_group("enemies")[0].global_position
		look_at(target)
		global_rotation_degrees.x = 0
		global_rotation_degrees.z = 0
		
		cam_fov = 10


func _on_button_pressed():
	close_gambling()


var is_baja = false
var baja_previous_pos = Vector3()

func _on_pp_timeout_timeout():
	if is_multiplayer_authority():
		if is_baja:
			var pos = global_position
			pos.y = 0
			
			if baja_previous_pos.distance_to(pos) > 0.75:
						parent.spawn_puddle.rpc(Vector3(global_position.x,0,global_position.z))
			baja_previous_pos = pos

func _on_baja_trail_timeout():
	is_baja = false

@export var max_sway_rotation: float = 1
@export var sway_smoothness: float = 10.0
@export var return_speed: float = 10.0

var sway_rotation: Vector3 = Vector3.ZERO
var original_rotation: Vector3

func arm_sway(delta):
	if !is_multiplayer_authority(): return
	var mouse_delta = Input.get_last_mouse_velocity()

	# Calculate sway rotation based on mouse movement
	if parent.do_vertical_camera_normal:
		sway_rotation.x = mouse_delta.y * max_sway_rotation * delta
	sway_rotation.y = -mouse_delta.x * max_sway_rotation * delta

	# Smooth the rotation and return to the original orientation
	var new_rotation = original_rotation + sway_rotation
	$Hand.rotation_degrees = lerp($Hand.rotation_degrees, new_rotation, delta * sway_smoothness)


func _on_voice_chat_toggled(toggled_on):
	AudioServer.set_bus_mute(5,!toggled_on)

func freezer_death():
	if is_in_freezer:
		die("freezer")
		$CanvasLayer/Control/Freezer/AnimationPlayer.play("RESET")
		$freezerDeath.stop()
