extends CharacterBody3D

const OG_SPEED = 6.0
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
@export var steam_name = Steam.getPersonaName()

var revive_poses = [Vector3(0, 1.2, -10), Vector3(-18, 1.2, -24), Vector3(-26, 1.2, -57), Vector3(34, 1.2, -47), Vector3(8, 1.2, -28)]

var is_suspended = false

var current_sample_rate: int = 48000
var loopback_enabled: bool = false
var is_voice_toggled: bool = false
var local_playback: AudioStreamGeneratorPlayback = null
var local_voice_buffer: PackedByteArray = PackedByteArray()
var use_optimal_sample_rate: bool = false

var is_on_top = false
var on_top_counter = 0

@onready var default = $visual_body/Default
@onready var perfect = $visual_body/Perfect
@onready var impossible = $visual_body/Impossible
@onready var freaky = $visual_body/Freaky


func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$nametag.text = Steam.getPersonaName()

	if is_multiplayer_authority():
		$CanvasLayer.show()
		get_cur_item()
		get_parent().hide_menu()
		pick_item(2)
		#$Local.stream_mix_rate = float(current_sample_rate)
		



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	if is_multiplayer_authority():

		
		if Achievements.check("impossible_ending"):
			perfect.visible = false
			default.visible = false
			impossible.visible = true
			freaky.visible = false
		elif Achievements.check("perfect_ending"):
			perfect.visible = true
			default.visible = false
			impossible.visible = false
			freaky.visible = false
		elif Achievements.check("freaky_ending"):
			perfect.visible = false
			default.visible = false
			impossible.visible = false
			freaky.visible = true
			
		
		check_for_voice()

		if global_position.z > 15:
			get_parent().skibidi.rpc_id(name.to_int())

		if Input.is_action_just_pressed("debug"):
			# TODO: Remove before giving to anyone else!!!!
			#report_map_bug()
			get_parent().on_collect_book.rpc(name.to_int(), "book1")

		#global_rotation_degrees.x = 0
		#global_rotation_degrees.z = 0

		if global_position.y >= 3.727:
			is_on_top = true
		else:
			is_on_top = false

		$Camera3D.current = true
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
							print(ray.get_collider().name)

							if ray.get_collider().is_in_group("vending_machine"):
								get_parent().use_vending_machine.rpc(name.to_int())

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
						elif get_cur_item() == 3:
							var evil_leahy = get_tree().get_first_node_in_group("enemies")
							var distance = global_position.distance_to(evil_leahy.global_position)

							if distance < 15:
								pick_item(-1)
								get_parent().appease_leahy.rpc(steam_name)
							else:
								var fox = get_tree().get_first_node_in_group("fox")
								var dist = global_position.distance_to(fox.global_position)
								print("fox dist: " + str(dist))
								if dist < 15:
									pick_item(-1)
									get_parent().mr_fox_collect.rpc()

		move_and_slide()

		progress_bar.value = lerp(progress_bar.value, float(stamina), 0.2)
		$Camera3D.fov = lerp($Camera3D.fov, float(cam_fov), 0.1)

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


func _input(event):
	if !is_multiplayer_authority():
		return

	if event is InputEventMouseMotion and get_parent().canPlayersMove:
		if can_move:
			if can_cam_move:
				rotate_y(deg_to_rad(event.relative.x * -0.3))


func _on_area_3d_area_entered(area):
	if !is_multiplayer_authority():
		return
	if is_dead:
		return

	print(area.name)
	if area.get_parent().is_in_group("Book"):
		get_parent().on_collect_book.rpc(name.to_int(), area.get_parent().name)
		Achievements.books_collected += 1
		Achievements.save_all()
	elif area.get_parent().is_in_group("enemies") and get_parent().game_started == true:
		if get_parent().absent == false:
			die("leahy")
			Achievements.deaths += 1
			Achievements.save_all()
	elif area.name == "Landmine" and get_parent().game_started == true:
		die("mine")

		get_parent().on_collect_book.rpc(name.to_int(), area.name)
		Achievements.deaths += 1
		Achievements.save_all()


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

	#print(stamina)


func _on_stamina_timeout_timeout():
	if !is_multiplayer_authority():
		return
	can_run = true


func _on_revive_timer_timeout():
	get_parent().set_played_dead.rpc(name.to_int(), false)
	if not is_suspended:
		global_position = get_parent().get_node("PlayerSpawns").get_children().pick_random().global_position
	else:
		global_position = Vector3(-50, 1.2, -18)
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
	pick_item(randi_range(0, 3))


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
	multiplayer.multiplayer_peer.close()
	get_tree().reload_current_scene()


func die(cause):
	$visual_body.global_rotation_degrees.x = 0
	can_move = false
	get_parent().set_played_dead.rpc(name.to_int(), true)
	$"CanvasLayer/Control/Died thing".show()
	$ReviveTimer.start()
	is_dead = true
	AudioServer.set_bus_mute(1, true)
	AudioServer.set_bus_mute(2, true)
	$"CanvasLayer/Control/Died thing/AudioStreamPlayer".play()
	#TODO: make this work $CollisionShape3D.disabled = true
	if cause == "leahy":
		$"CanvasLayer/Control/Died thing/jumpscare".play()

		var chance = randi_range(0, 3)
		if chance == 2:
			$CanvasLayer/Control/silentLunch.show()
			is_suspended = true
			$"Silent Lunch".start()

	elif cause == "mine":
		$"CanvasLayer/Control/Died thing/jumpscare2".play()
	elif cause == "wall":
		$"CanvasLayer/Control/Died thing/jumpscare3".play()


func check_for_voice() -> void:
	var available_voice: Dictionary = Steam.getAvailableVoice()
	if available_voice["result"] == Steam.VOICE_RESULT_OK and available_voice["buffer"] > 0:
		print("Voice message found")
		# Valve's getVoice uses 1024 but GodotSteam's is set at 8192?
		# Our sizes might be way off; internal GodotSteam notes that Valve suggests 8kb
		# However, this is not mentioned in the header nor the SpaceWar example but -is- in Valve's docs which are usually wrong
		var voice_data: Dictionary = Steam.getVoice()
		if voice_data["result"] == Steam.VOICE_RESULT_OK and voice_data["written"]:
			Networking.send_message(voice_data["buffer"])
			# If loopback is enable, play it back at this point
			if loopback_enabled:
				process_voice_data(voice_data, "local")


func process_voice_data(voice_data: Dictionary, voice_source: String) -> void:
	get_sample_rate()

	var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data["buffer"], voice_data["written"], current_sample_rate)

	if not decompressed_voice["result"] == Steam.VOICE_RESULT_OK or decompressed_voice["size"] == 0 or not voice_source == "local":
		return

	if local_playback.get_frames_available() <= 0:
		return

	local_voice_buffer = decompressed_voice["uncompressed"]
	local_voice_buffer.resize(decompressed_voice["size"])

	for i: int in range(0, mini(local_playback.get_frames_available() * 2, local_voice_buffer.size()), 2):
		# Combine the low and high bits to get full 16-bit value
		var raw_value: int = local_voice_buffer[0] | (local_voice_buffer[1] << 8)
		# Make it a 16-bit signed integer
		raw_value = (raw_value + 32768) & 0xffff
		# Convert the 16-bit integer to a float on from -1 to 1
		var amplitude: float = float(raw_value - 32768) / 32768.0
		local_playback.push_frame(Vector2(amplitude, amplitude))
		local_voice_buffer.remove_at(0)
		local_voice_buffer.remove_at(0)


func get_sample_rate() -> void:
	var optimal_sample_rate: int = Steam.getVoiceOptimalSampleRate()
	# SpaceWar uses 11000 for sample rate?!
	# If are using Steam's "optimal" rate, set it; otherwise we default to 48000
	if use_optimal_sample_rate:
		current_sample_rate = optimal_sample_rate
	else:
		current_sample_rate = 48000
	print("Current sample rate: " + str(current_sample_rate))


func _on_timer2_timeout():
	$Local.play()
	local_playback = $Local.get_stream_playback()
	loopback_enabled = true

	use_optimal_sample_rate = true
	get_sample_rate()
	$Local.stream.mix_rate = current_sample_rate


func change_voice_status() -> void:
	# Let Steam know that the user is currently using voice chat in game.
	# This will suppress the microphone for all voice communication in the Steam UI.
	# TODO: Change 480 to something else
	Steam.setInGameVoiceSpeaking(480, is_voice_toggled)

	if is_voice_toggled:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()


func _on_silent_lunch_timeout():
	is_suspended = false
	$CanvasLayer/Control/silentLunch.hide()


func _on_anti_wall_walk_timeout():
	if is_on_top:
		print("on top")
		on_top_counter += 1

		if on_top_counter == 10:
			die("wall")
			on_top_counter = 0
			global_position.y = 1
	else:
		on_top_counter = 0


@onready var http = $http


func report_map_bug():
	if !can_debug: return
	var body = {
		"content": "",
		"tts": false,
		"embeds":
		[
			{
				"id": 764355288,
				"fields": [{"id": 80383102, "name": "Position", "value": str(global_position)}],
				"title": "Map bug",
				"color": 16711680,
				"footer": {"text": "Reported by " + steam_name}
			}
		],
		"components": [],
		"actions": {},
		"username": "Debug"
	}

	http.request(
		"https://discord.com/api/webhooks/1249927945716367371/zPJNBJ9EyCH-nP7musr59IcOZ2TJCqWnGURASuKvLVL3Ge5qyFdHH_LkyoUSqBhjpxgq",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	can_debug = false

var can_debug = true

func _on_debug_timeout():
	can_debug = true
