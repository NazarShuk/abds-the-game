extends CharacterBody3D
class_name Player

const OG_SPEED = 6.0
var SPEED = OG_SPEED
var speed_multiplier = 1
var run_multiplier = 1

var is_boosted = false

const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var books_collected = 0

var inventory = []
var selected_slot = 0
var max_slots = 3
@export var hand : Node3D
signal inventory_changed

var is_running = false
var stamina = 100
var can_run = true
var is_moving = false
var can_move = true
var is_ragdolled = false

@onready var progress_bar: ProgressBar = $"CanvasLayer/Control/Progress bar handler/ProgressBar"
@onready var progress_bar_handler = $"CanvasLayer/Control/Progress bar handler"

@export var is_dead = false

@onready var ray = $RayCast3D

var cam_fov = 75
var can_cam_move = true
@export var steam_name : String = "Loading..."

var is_suspended = false

var is_on_top = false
var on_top_counter = 0

var can_get_item = true

@export var camera_3d : Camera3D
@onready var minimap_cam = $Minimap/Camera3D

var leahy_dst = 0

var credits = 0
var can_use_shop = true

@export var controls_text : Label

var parent = null

@onready var leahy_approaching = $CanvasLayer/Control/LeahyApproaching

@onready var shop_timer = $"CanvasLayer/Control/Shop/shop timer"

var is_freaky = false
var can_use_breaker = true
var can_use_coffee = true

var can_toilet_tp = true

const push_force = 1.0

var is_baja = false
var baja_previous_pos = Vector3()

var last_breath = false

@onready var tv: Control = $CanvasLayer/Control/TV

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$nametag.text = SteamManager.steam_name
	steam_name = SteamManager.steam_name
	parent = get_parent()
	
	$CanvasLayer.hide()
	if is_multiplayer_authority():
		$CanvasLayer.show()


func _ready():
	if is_multiplayer_authority():
		GuiManager.hide_cursor()
		
		$visual_body.pick_skin()
		GlobalVars.current_skin = $visual_body.duplicate()
		$visual_body.hide()
		
		if Settings.render_distance:
			camera_3d.far = Settings.render_distance
		
		GuiManager.show_tip_once("movement_controls","[color=green]Movement[/color]\nWASD to move, LeftShift to run (consumes stamina), Space to look behind, M to open the minimap")
		
		inventory.resize(max_slots)
		for i in range(max_slots):
			inventory[i] = -1

func _physics_process(delta):
	if is_multiplayer_authority():
		if !get_tree(): return
		
		if Input.is_action_just_released("zoom_in"):
			
			var slot = selected_slot + 1
			if slot > inventory.size() - 1:
				slot = 0
			
			select_item(slot)
		if Input.is_action_just_released("zoom_out"):
			var slot = selected_slot - 1
			if slot < 0:
				slot = inventory.size() - 1
			select_item(slot)
		
		
		if Input.is_action_just_pressed("submit") and is_shop_open:
			_on_submit_button_pressed() 
		
		if Input.is_action_just_pressed("debug") and OS.has_feature("debug"):
			buy_book_rpc.rpc(steam_name, name.to_int())
		if Input.is_action_just_pressed("revive") and OS.has_feature("debug"):
			add_speed_boost(2,1)
		
		if Input.is_action_just_pressed("revive"):
			if is_dead_of_dariel:
				_on_revive_timer_timeout()
		
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
					GuiManager.show_cursor()
				else:
					$Minimap.process_mode = Node.PROCESS_MODE_DISABLED
					GuiManager.hide_cursor()
		
		can_cam_move = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		
		minimap_cam.size = lerp(minimap_cam.size,float(minimap_zoom),0.25)
		minimap_zoom = clamp(minimap_zoom,5,95)

		
		SPEED = clamp(OG_SPEED * speed_multiplier * run_multiplier,0,99999)
		if !parent.leahy_look:
			cam_fov = 75 + (speed_multiplier * run_multiplier) * 15
		
		$HandTree.set("parameters/time_scale/scale", run_multiplier * speed_multiplier)
		
		$CanvasLayer/Control/Shop/ColorRect/timer.text = str(floor(shop_timer.time_left)) + "s left"
		$"CanvasLayer/Control/Shop/ColorRect/question panel/TextureRect/Seconds/Label".text = str(floor(shop_timer.time_left))
		
		$CanvasLayer/Control/Shop/ColorRect/Label2.text = str(credits)
		$"CanvasLayer/Control/Shop/ColorRect/question panel/TextureRect/Smartscore/Label".text = str(credits)
		
		
		var closest_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
		if closest_leahy:
			leahy_dst = global_position.distance_to(closest_leahy.global_position)
		else:
			leahy_dst = -1
		
		if closest_leahy:
			if Game.game_started:
				if (10 - leahy_dst) > 0:
					var strength = 1/leahy_dst+0.01
					camera_3d.h_offset = randf_range(-strength,strength) / 5
					camera_3d.v_offset = randf_range(-strength,strength) / 5
				else:
					camera_3d.h_offset = 0
					camera_3d.v_offset = 0
				
				if closest_leahy.target_player_name and !parent.can_escape:
					if global_position.y < 3.7:
						if closest_leahy.target_player_name == steam_name:
							if (closest_leahy.appeased == false && closest_leahy.absent == false && closest_leahy.baja_blasted == false):
								leahy_approaching.is_shown = true
								leahy_approaching.distance = leahy_dst
							else:
								leahy_approaching.is_shown = false
						else:
							leahy_approaching.is_shown = false
					else:
						leahy_approaching.is_shown = false
				else:
					leahy_approaching.is_shown = false
		
		if global_position.z > 15 && !is_freaky:
			if !Game.game_started:
				is_freaky = true
				parent.skibidi.rpc()
			else:
				global_position.z = 0
				GuiManager.show_tip("Whoops, sorry about that.", 5)
		
		movement_function(delta)
		
		progress_bar.value = lerp(progress_bar.value, float(stamina), 0.2)
		camera_3d.fov = clamp(lerp(camera_3d.fov, float(cam_fov), 0.1),1,140)
		
		
		camera_3d.current = true
		camera_3d.global_transform = $"Camera target".global_transform
		
		if parent.can_escape and not is_dead:
			$CanvasLayer/Control.do_shake = true
		else:
			$CanvasLayer/Control.do_shake = false

var vertical_angle = 0.0
var max_vertical_angle = 89.0  # You can adjust this as needed.

func _input(event):
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		if can_move:
			if can_cam_move:
				rotate_y(deg_to_rad(event.relative.x * -0.3))
				if Game.game_params.get_param("vertical_camera"):
					# funni
					rotate_x(deg_to_rad(event.relative.y * -0.3))
				
				if parent.do_vertical_camera_normal:
					# Calculate new vertical angle
					vertical_angle -= event.relative.y * 0.3
					vertical_angle = clamp(vertical_angle, -max_vertical_angle, max_vertical_angle)
					
					# Set the new rotation by using Euler angles
					rotation.x = deg_to_rad(vertical_angle)
	
	if event is InputEventKey:
			if event.pressed:
				var regex = RegEx.new() # Create a new RegEx object
				var pattern = "^[0-9]+$" # Pattern to allow only numbers from 0-9
				regex.compile(pattern) # Compile the pattern
				
				if regex.search(event.as_text_keycode()):
					if event.as_text_keycode().to_int() < inventory.size() + 1:
						select_item(event.as_text_keycode().to_int() - 1)
					else:
						select_item(0)
	

func toilet_tp_timeout():
	await Game.sleep(60)
	can_toilet_tp = true

var is_in_leahy = false

func _on_area_3d_area_entered(area):
	if !is_multiplayer_authority():
		return
	if is_dead:
		return
	if is_shop_open: return
	if area.get_parent().is_in_group("Book"):
		Achievements.books_collected += 1
		Achievements.save_all()
		tv.switch("book")
		if parent.leahy_time:
			play_sound("res://sounds/sfx_collecttoppin.ogg",6)
	elif area.get_parent().is_in_group("evil_leahy") and Game.game_started == true:
		var evil_leahy = area.get_parent()
		
		if evil_leahy.absent == false:
			if Game.powered_off == false:
				if evil_leahy.appeased == false:
					if evil_leahy.baja_blasted == false:
						die("leahy")

	elif area.is_in_group("landmine") and Game.game_started == true:
		landmine_slip()
		tv.switch("banana")
	elif area.name == "azzu":
		if area.get_parent().angered:
			die("azzu")
	elif area.name == "gainy":
		if area.get_parent().angered:
			die("gainy")
	elif area.name == "puddle":
		if !area.get_parent().can_slowdown: return
		add_speed_boost(-0.5, 3)
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

func landmine_slip():
	velocity.y += 5
	is_ragdolled = true
	apply_random_rotation()
	
	if !$Banana.is_stopped():
		$Banana.start($Banana.time_left + 3)
		return
	else:
		$Banana.start(3)
	
	await $Banana.timeout
	
	is_ragdolled = false
	global_rotation_degrees.x = 0
	global_rotation_degrees.z = 0

func apply_random_rotation():
	# Generate a random rotation axis
	var random_axis = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()
	
	# Generate a random rotation angle (in radians)
	var random_angle = randf_range(0, PI * 2)  # Full rotation range
	
	# Apply the rotation
	rotate(random_axis, random_angle)

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
				if parent.leahy_time:
					run_multiplier = 4
				else:
					run_multiplier = 2
					stamina -= 1
		else:
			is_running = false
			can_run = false
			$Stamina_timeout.start()
			GuiManager.show_tip_once("stamina_timeout","[color=green]Stamina[/color]\nIf stamina [b]reaches 0[/b], you will not be able to run for a few seconds.")
			
	else:
		if parent.leahy_time:
			run_multiplier = 2
		else:
			run_multiplier = 1
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
	
	is_ragdolled = false
	global_rotation_degrees.x = 0
	global_rotation_degrees.z = 0
	
	await Game.sleep(5)
	is_dead = false

# Add item to first empty slot
func add_item(item_id: int) -> bool:
	for i in range(inventory.size()):
		if inventory[i] == -1:  # Empty slot
			inventory[i] = item_id
			inventory_changed.emit()
			
			select_item(i)
			
			return true
	throw_item(item_id)
	return false  # Inventory full

# Remove item from specific slot
func remove_item(slot: int) -> int:
	if slot >= 0 and slot < inventory.size():
		var item_id = inventory[slot]
		inventory[slot] = -1
		select_item(slot)
		inventory_changed.emit()
		return item_id
	return -1

func remove_item_by_id(id : int) -> int:
	for i in range(0,inventory.size()):
		if inventory[i] == id:
			remove_item(i)
			inventory_changed.emit()
			return i
	return -1

# Select and display item
func select_item(slot: int):
	if slot < 0 or slot >= inventory.size():
		selected_slot = -1
	else:
		selected_slot = slot
	
	# Hide all items first
	for i in hand.get_children().size():
		set_item_vis.rpc(i, false)
	
	# Show selected item if any
	if selected_slot != -1 and inventory[selected_slot] != -1:
		set_item_vis.rpc(inventory[selected_slot], true)
		$HandTree.set("parameters/pickup/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
# Get currently selected item ID
func get_selected_item() -> int:
	if selected_slot != -1:
		return inventory[selected_slot]
	return -1

@rpc("any_peer","call_local")
func set_item_vis(item : int,vis : bool):
	hand.get_child(item).visible = vis

var item_weights = {}

func update_item_weights():
	var book_multiplier = (Game.collected_books / Game.books_to_collect) * 3
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
			add_item(pick_random_weighted(item_weights).to_int())
	else:
		if ov_timeout:
			if !can_get_item: return
			can_get_item = false
		
		add_item(item_ov)

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

@rpc("any_peer", "call_local")
func spawn_clorox(pos, rot, launcher):
	if multiplayer.is_server():
		var packed_clorox = load("res://Clorox Wipes.tscn")
		var clorox: StaticBody3D = packed_clorox.instantiate()
		
		get_parent().add_child(clorox)
		
		clorox.initial_pos = pos #$RayCast3D.global_position
		clorox.global_position = pos #$RayCast3D.global_position
		clorox.global_rotation = rot #$"Camera target".global_rotation
		clorox.launcher = launcher #name.to_int()
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
func die(cause, do_die = true):
	if is_dead: return
	if last_breath:
		$"CanvasLayer/Control/Last breath/anim".play("boom")
		$"CanvasLayer/Control/Last breath/audio".play()
		last_breath = false
		add_speed_boost(1, 3)
		is_dead = true
		await Game.sleep(5)
		is_dead = false
		return
	
	$Banana.start(0.01)
	is_ragdolled = false
	$visual_body.global_rotation_degrees.x = 0
	can_move = false
	parent.set_player_dead.rpc(name.to_int(), true, do_die)
	$"CanvasLayer/Control/Died thing".show()
	if !parent.can_escape:
		$ReviveTimer.start(5)
	else:
		if parent.leahy_time:
			$ReviveTimer.start(5)
	
	is_dead = true
	if !parent.can_escape:
		AudioServer.set_bus_mute(1, true)
	AudioServer.set_bus_mute(2, true)
	$"CanvasLayer/Control/Died thing/AudioStreamPlayer".play()
	#TODO: make this work $CollisionShape3D.disabled = true
	Achievements.deaths += 1
	Achievements.save_all()
	close_shop(false)
	
	death_cause = cause
	
	for i in range(0, inventory.size()):
		if inventory[i] != -1:
			throw_item(inventory[i])
			remove_item(i)
	
	velocity.y += 5
	is_ragdolled = true
	apply_random_rotation()
	
	if cause == "leahy":
		$"CanvasLayer/Control/Died thing/jumpscare".play()
		if Game.game_params.get_param("silent_lunch"):
			var chance = randi_range(0, 2)
			if chance == 0:
				$CanvasLayer/Control/silentLunch.show()
				$CanvasLayer/Control/silentLunch.text = "You got silent lunch\nyou can leave in 15" 
				is_suspended = true
				$"Silent Lunch".start(15)
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
			die("wall")
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
		GuiManager.show_cursor()
		AudioServer.set_bus_solo(6,true)
		parent.set_player_dead.rpc(name.to_int(), true,false)
		can_use_shop = false
		Game.get_closest_node_in_group(global_position,"shop").hide()
		shop_timer.start(30)
		$CanvasLayer/Control/Shop/ColorRect/MainPanel.show()
		$"CanvasLayer/Control/Shop/ColorRect/question panel".hide()
		$"CanvasLayer/Control/Shop/ColorRect/rewards panel".hide()
		is_shop_open = true

func close_shop(set_death = true):
	$CanvasLayer/Control/Shop.hide()
	$CanvasLayer/Control/Shop/AudioStreamPlayer.stop()
	GuiManager.hide_cursor()
	AudioServer.set_bus_solo(6,false)
	if set_death:
		parent.set_player_dead.rpc(name.to_int(), false,false)
	shop_timer.stop()
	is_shop_open = false
	if $ShopTimeout.is_stopped():
		$ShopTimeout.start(60)

func _on_shop_timeout_timeout():
	can_use_shop = true
	var closest_shop = Game.get_closest_node_in_group(global_position,"shop")
	if closest_shop:
		closest_shop.show()

func _on_credits_btn_pressed():
	$"CanvasLayer/Control/Shop/ColorRect/question panel".show()
	$CanvasLayer/Control/Shop/ColorRect/MainPanel.hide()
	generate_show_question()
	

func _on_shop_timer_timeout():
	close_shop()

func _on_rewards_btn_pressed():
	$CanvasLayer/Control/Shop/ColorRect/MainPanel.hide()
	$"CanvasLayer/Control/Shop/ColorRect/rewards panel".show()

var right_ans

@onready var line_edit = $"CanvasLayer/Control/Shop/ColorRect/question panel/TextureRect/LineEdit"


func generate_show_question():
	var num1 = randi_range(1,55)
	var num2 = randi_range(1,55)
	right_ans = num1 + num2
	
	line_edit.text = ""
	$"CanvasLayer/Control/Shop/ColorRect/question panel/TextureRect/Label2".text = str(num1) + " + " + str(num2) + " ="

func _on_submit_button_pressed():
	if line_edit.text.to_int() == right_ans:
		credits += 5
		generate_show_question()
		$CanvasLayer/Control/Shop/correct.play()
		$"CanvasLayer/Control/Shop/ColorRect/question panel/AnsweredAnimation".show()
		shop_timer.start(shop_timer.time_left + 2.5)
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
		buy_book_rpc.rpc(steam_name, name.to_int())
		Achievements.books_collected += 1
		Achievements.save_all()
		
		play_sound("res://money.mp3",0,"shop")

@rpc("any_peer","call_local")
func buy_book_rpc(pname, id):
	$CanvasLayer/Control/TV.switch("moneyminor")
	if multiplayer.is_server():
		
		Game.players[name.to_int()].books_collected += 1 + Game.book_boost
		Game.calculate_total_books()
		
		if not Game.competitive:
			Game.info_text(pname + " bought a notebook")
		else:
			var total_books = 0
			for idx in Game.players:
				if Game.players[idx].team == Game.players[id].team:
					total_books += Game.players[id].books_collected
			
			var notebook_text = str(total_books)
			
			if total_books == 1:
				notebook_text += "st"
			elif total_books == 2:
				notebook_text += "nd"
			elif total_books == 3:
				notebook_text += "rd"
			else:
				notebook_text += "th"
			
			Game.info_text("Team " + Game.players[id].team + " bought their " + notebook_text + " notebook")

func _on_buy_duck_pressed():
	if credits >= 10:
		credits -= 10
		add_item(4)
		
		play_sound("res://money.mp3",0,"shop")

func _on_buy_baja_pressed():
	if credits >= 15:
		credits -= 15
		add_item(8)
		
		play_sound("res://money.mp3",0,"shop")

func _on_breaker_timeout_timeout():
	can_use_breaker = true


func _on_coffee_timeout_timeout():
	can_use_coffee = true

func play_sound(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20):
	play_sound_rpc.rpc(stream_path,volume_db,bus,max_distance,global_position)

@rpc("any_peer","call_local")
func play_sound_rpc(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20,pos = Vector3()):
	if !multiplayer.is_server(): return
	
	var a = load("res://player_sound.tscn").instantiate()
	get_parent().add_child(a,true)
	
	var audio_stream : AudioStream = load(stream_path)
	
	actually_play_sound.rpc(a.get_path(),stream_path,volume_db,bus,max_distance,pos)
	
	await Game.sleep(audio_stream.get_length())
	a.queue_free()

@rpc("any_peer","call_local")
func actually_play_sound(sound_path, stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20,pos = Vector3()):
	var sound = get_node(sound_path)
	if sound:
		sound.stream = load(stream_path)
		sound.bus = bus
		sound.max_distance = max_distance
		sound.volume_db = volume_db
		sound.global_position = pos
		sound.play()


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
	if parent.leahy_time:
		controls_text.text = ""
		return
	var looking_at = ray.get_collider()
	
	var final_text = ""
	if looking_at:
		if looking_at.is_in_group("vending_machine"):
			final_text += "Vending Machine\nE - grab item"
		elif looking_at.name == "CoffeMachine":
			final_text += "Coffee Machine\n" + format_time("Coffee timeout","E - drink")
		elif looking_at.is_in_group("shop"):
			final_text += "The Shop\n" + format_time("ShopTimeout","E - open the shop")
		elif looking_at.name == "Breaker":
			final_text += "The Breaker\n" + format_time("BreakerTimeout","E - turn off power")
		elif looking_at.is_in_group("toilet"):
			final_text += "Toilet\n" + format_time("ToiletTimeout","E - flush down")
		elif looking_at.name == "water fountain":
			if get_selected_item() != 7:
				final_text += "Water fountain\nE - Drink"
			else:
				if !hand.get_node("Bucket 7/Bucket/water").visible:
					final_text += "Water fountain\nE - fill the bucket"
				else:
					final_text += "Water fountain\nBucket is full"
		elif looking_at.is_in_group("mr_misuraca"):
			final_text += "Mr.Misuraca\nE - Make a bet"
		elif looking_at.is_in_group("video_player"):
			final_text += "Video player\n E - play"
		elif looking_at.name == "wheel":
			final_text += "Wheel\n E - Spin"
		elif looking_at.is_in_group("fence"):
			final_text += "Wheel\n You need more notebooks to spin it!"
		elif looking_at.is_in_group("freezer"):
			final_text += "Freezer\n E - Get inside"
		elif looking_at.is_in_group("dropped_item"):
			final_text += "Dropped item\n E - Pick it up"
		elif looking_at.is_in_group("ignis_car"):
			final_text += "Car\n E - Get inside"
	
	var cur_item = get_selected_item()
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
		if hand.get_node("Bucket 7/Bucket/water").visible:
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

# GAMBLING

var gamble = []

func open_gambling():
	GuiManager.show_cursor()
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
		
		$CanvasLayer/Control/paper.get_node(NodePath("gamble" + str(i + 1))).text = "if you get %s notebooks in %s seconds, i will give everyone a %s. If you don't, i will take %s books." % [g.books,g.time,hand.get_child(g.reward).name,g.loss]
		parent.set_player_dead.rpc(name.to_int(), true,false)

func close_gambling(do_deaths = true):
	GuiManager.hide_cursor()
	$CanvasLayer/Control/paper.hide()
	if do_deaths:
		parent.set_player_dead.rpc(name.to_int(), false,false)


func _on_gamblebtn_1_pressed():
	parent.do_bet.rpc(steam_name,gamble[0].books,gamble[0].time,gamble[0].loss,gamble[0].reward,hand.get_child(gamble[0].reward).name)
	close_gambling()


func _on_gamblebtn_2_pressed():
	parent.do_bet.rpc(steam_name,gamble[1].books,gamble[1].time,gamble[1].loss,gamble[1].reward,hand.get_child(gamble[1].reward).name)
	close_gambling()


func _on_gamblebtn_3_pressed():
	parent.do_bet.rpc(steam_name,gamble[2].books,gamble[2].time,gamble[2].loss,gamble[2].reward,hand.get_child(gamble[2].reward).name)
	close_gambling()



# MOVEMENT

var is_in_freezer = false

func movement_function(delta):
	
	if not is_on_floor() and not is_dead:
		velocity.y -= gravity * delta
	
	if global_position.y >= 3.727 and is_on_floor():
		is_on_top = true
	else:
		is_on_top = false
	
	if Input.is_action_pressed("jump"):
		$"Camera target".rotation_degrees.y = 180
	else:
		$"Camera target".rotation_degrees.y = 0
	
	
	if Input.is_action_just_pressed("sprint"):
		is_running = true
	elif Input.is_action_just_released("sprint"):
		is_running = false
	
	$walking.volume_db = -80
	
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
				
				if not is_ragdolled:
					if movement != Vector3.ZERO:
						velocity.x = (movement * SPEED).x
						velocity.z = (movement * SPEED).z
						$walking.volume_db = 0
						is_moving = true
					else:
						velocity.x = velocity.move_toward(Vector3.ZERO, SPEED).x
						velocity.z = velocity.move_toward(Vector3.ZERO, SPEED).z
						is_moving = false
				else:
					for i in get_slide_collision_count():
						var collision = get_slide_collision(i)
						if collision.get_collider() is StaticBody3D:
							var normal = collision.get_normal()
							
							# Check if the collision is on the sides (not floor or ceiling)
							if abs(normal.y) < 0.1:  # Tolerance for slight slopes
								# Calculate bounce direction (only for x and z components)
								var bounce_dir = Vector3(normal.x, 0, normal.z).normalized()
								
								# Apply bounce only to horizontal components
								velocity.x = bounce_dir.x * 30
								velocity.z = bounce_dir.z * 30
								
								var rotation_axis = Vector3(-bounce_dir.z, 0, bounce_dir.x)
								
								rotate(rotation_axis, 5.0 * delta)
								velocity.y += 1
								if !$Banana.is_stopped():
									$Banana.start($Banana.time_left + 0.5)
								
								play_sound("res://parry-ultrakill.mp3")
								
					velocity.x *= 0.99
					velocity.z *= 0.99
				
				move_and_slide()
				
				# Update is_moving based on actual movement
				if velocity.length() < 0.1:
					is_moving = false
					$HandTree.set("parameters/Transition/transition_request","static")
				else:
					$HandTree.set("parameters/Transition/transition_request","swing")
				
				
				
				interaction_functions()
				item_give_functions()
				item_use_functions()
	
	if Input.is_action_just_pressed("throw"):
		if get_selected_item() != -1:
			throw_item(get_selected_item())
		
		remove_item(selected_slot)
		
	if parent.leahy_look:
		var target = Game.get_closest_node_in_group(global_position,"enemies")
		
		if target:
			look_at(target.global_position)
			global_rotation_degrees.x = 0
			global_rotation_degrees.z = 0
			
			cam_fov = 10

func throw_item(item_id):
	var cloned_item = hand.get_child(item_id).get_child(0).get_path()
	parent.spawn_dropped_item.rpc(hand.global_position,cloned_item,item_id)

@rpc("any_peer","call_local")
func spawn_smoke(pos):
	if multiplayer.is_server():
		var smoke = load("res://smoke wall.tscn").instantiate()
		get_tree().get_first_node_in_group("school_navigation").add_child(smoke,true)
		smoke.global_position = pos
		smoke.navigation_mesh = get_tree().get_first_node_in_group("school_navigation")

@rpc("any_peer","call_local")
func spawn_puddle(pos):
	if multiplayer.is_server():
		var puddle = load("res://puddle.tscn").instantiate()
		get_parent().add_child(puddle,true)
		puddle.global_position = pos

func _on_button_pressed():
	close_gambling()

func _on_pp_timeout_timeout():
	if is_multiplayer_authority():
		if is_baja:
			var pos = global_position
			pos.y = 0
			
			if baja_previous_pos.distance_to(pos) > 0.75:
				spawn_puddle.rpc(Vector3(global_position.x,0,global_position.z))
			baja_previous_pos = pos

func interaction_functions():
	if Input.is_action_just_pressed("interact"):
		if ray.get_collider() != null:
			if ray.get_collider().is_in_group("vending_machines"):
				var vending_machine = ray.get_collider()
				
				if vending_machine.uses_left > 0:
					if Game.game_started:
						choose_item(-1)
					else:
						add_item(2)
					vending_machine.use_vending_machine.rpc()
				else:
					GuiManager.show_tip_once("vending_broke","[color=green]Vending Machines[/color]\nVending machines will [b]break[/b] after being used way too much. [b]Mr.Misuraca[/b] will come and [b]fix them.[/b]")
			
		if ray.get_collider() != null and Game.game_started:
			if ray.get_collider().is_in_group("shop"):
				open_shop()
			if ray.get_collider().is_in_group("coffee_machine"):
				if !can_use_coffee: return
				add_speed_boost(1, 6)
				ray.get_collider().play_sound.rpc()
				can_use_coffee = false
				$"Coffee timeout".start(20)
			if ray.get_collider().name == "Breaker":
				if !can_use_breaker: return
				
				
				ray.get_collider().toggle_power.rpc()
				
				can_use_breaker = false
				$BreakerTimeout.start(60)
			if ray.get_collider().is_in_group("mr_misuraca"):
				if !Game.competitive:
					open_gambling()
				else:
					Game.rpc_info_text("Bets are disabled in competitive mode")
			
			if ray.get_collider().is_in_group("dropped_item"):
				if ray.get_collider():
					ray.get_collider().remove_item.rpc()
					add_item(ray.get_collider().item)
			
			if ray.get_collider().is_in_group("video_player"):
				ray.get_collider().play.rpc()
			
			if ray.get_collider().name == "fire":
				ray.get_collider().get_parent().break_glass.rpc()
				if ray.get_collider().get_parent().can_pickup:
					add_item(9)
				
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
			if ray.get_collider().is_in_group("last_breath"):
				ray.get_collider().queue_free()
				last_breath = true
			if ray.get_collider().is_in_group("ignis_car"):
				print("the ignis")
				ray.get_collider().enter_car.rpc(name.to_int())
				
			if ray.get_collider().is_in_group("toilet"):
				if !can_toilet_tp : return
				var spawns = get_tree().get_nodes_in_group("bathroom_spawn")
				
				var farthest_dst = -1
				var farthest_obj
				
				for spawn in spawns:
					if global_position.distance_to(spawn.global_position) > farthest_dst:
						farthest_dst = global_position.distance_to(spawn.global_position)
						farthest_obj = spawn
				can_toilet_tp = false
				$ToiletTimeout.start()
				$CanvasLayer/Control/toilet.show()
				global_position = farthest_obj.global_position
				await Game.sleep(2)
				play_sound("res://flush.mp3",5)
			if ray.get_collider():
				if ray.get_collider().is_in_group("blackboard"):
					ray.get_collider().open_ui()
			
			
			if ray.get_collider():
				if ray.get_collider().is_in_group("water fountain"):
					if get_selected_item() == 7:
						hand.get_node("Bucket 7/Bucket/water").show()
					else:
						stamina = 100
			if ray.get_collider():
				if ray.get_collider().is_in_group("bucket"):
					add_item(7)

func item_use_functions():
	if Input.is_action_just_pressed("use_item"):
		if get_selected_item() == 0:
			remove_item(selected_slot)
			add_speed_boost(1, 3)
		elif get_selected_item() == 1:
			remove_item(selected_slot)
			spawn_clorox.rpc($RayCast3D.global_position, $"Camera target".global_rotation, name.to_int())
		elif get_selected_item() == 2:
			remove_item(selected_slot)
			velocity.y += 20
			add_speed_boost(0.5,1)
			shart.rpc()
		elif get_selected_item() == 4:
			if !Game.competitive:
				squeak.rpc()
				remove_item(selected_slot)
				parent.start_da_pacer.rpc(name.to_int()) # i want to kms because of this
			else:
				Game.rpc_info_text("The Pacer is disabled in competitive mode")
		elif get_selected_item() == 6:
			remove_item(selected_slot)
			add_speed_boost(2, 3)
			play_sound("res://redbull.mp3")
		elif get_selected_item() == 7:
			
			if hand.get_node("Bucket 7/Bucket/water").visible:
				hand.get_node("Bucket 7/Bucket/water").visible = false
				remove_item(selected_slot)
				play_sound("res://water.mp3")
				
				spawn_puddle.rpc(Vector3(global_position.x,0,global_position.z))
		elif get_selected_item() == 8:
			remove_item(selected_slot)
			is_baja = true
			
			add_speed_boost(4,7.5)
			$"baja trail".start()
		elif get_selected_item() == 9:
			remove_item(selected_slot)
			spawn_smoke.rpc(global_position)
			play_sound("res://fire extinguisher.mp3")
		elif get_selected_item() == 10:
			remove_item(selected_slot)
			add_speed_boost(3,5)
			play_sound("res://models/sonic.mp3",3)

func item_give_functions():
	if Input.is_action_just_pressed("give"):
		if get_selected_item() == 3:
			var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
			var distance = INF
			if evil_leahy:
				distance = global_position.distance_to(evil_leahy.global_position)
			
			var fox = Game.get_closest_node_in_group(global_position,"mr_fox")
			var dist = INF
			
			if fox:
				dist = global_position.distance_to(fox.global_position)
			
			if dist < 20:
				remove_item(selected_slot)
				fox.mr_fox_collect.rpc(1)
			elif distance < 15:
				remove_item(selected_slot)
				evil_leahy.appease.rpc(steam_name,5)
		elif get_selected_item() == 5:
			var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
			var distance = INF
			if evil_leahy:
				distance = global_position.distance_to(evil_leahy.global_position)
			
			var fox = Game.get_closest_node_in_group(global_position,"mr_fox")
			var dist = INF
			
			if fox:
				dist = global_position.distance_to(fox.global_position)
			
			if dist < 30:
				remove_item(selected_slot)
				fox.mr_fox_collect.rpc(2)
			elif distance < 30:
				remove_item(selected_slot)
				evil_leahy.appease.rpc(steam_name,15)
			
		elif get_selected_item() == 6:
			var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
			var distance = global_position.distance_to(evil_leahy.global_position)
			
			if distance < 10:
				remove_item(selected_slot)
				evil_leahy.boost_leahy.rpc(steam_name)
		elif get_selected_item() == 8:
			var evil_leahy = Game.get_closest_node_in_group(global_position,"evil_leahy")
			var distance = global_position.distance_to(evil_leahy.global_position)
			
			if distance < 10:
				remove_item(selected_slot)
				evil_leahy.baja_blast_her.rpc(steam_name)

func _on_baja_trail_timeout():
	is_baja = false

func _on_voice_chat_toggled(toggled_on):
	AudioServer.set_bus_mute(5,!toggled_on)

func freezer_death():
	if is_in_freezer:
		die("freezer")
		$CanvasLayer/Control/Freezer/AnimationPlayer.play("RESET")
		$freezerDeath.stop()

func add_speed_boost(multiplier : float, duration : float):
	speed_multiplier += multiplier
	await Game.sleep(duration)
	speed_multiplier -= multiplier
