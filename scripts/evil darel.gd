extends CharacterBody3D

@export var health = 100

const LIL_DAREL = preload("res://lil_darel.tscn")
const DAREL_BALL = preload("res://darel_ball.tscn")
const DAREL_RAY = preload("res://darel ray.tscn")
const EXPLOSION = preload("res://explosion.tscn")
const BIGGER_EXPLOSION = preload("res://bigger_explosion.tscn")
const SHOCKWAVE = preload("res://shockwave.tscn")

const FULL_AUTO = preload("res://dariel/full auto.mp3")
const FULLER = preload("res://dariel/fuller.mp3")
const GETOVER = preload("res://dariel/getover.mp3")
const HOLD_ON = preload("res://dariel/hold on.mp3")
const MAGIC = preload("res://dariel/magic.mp3")


@export var screams : Array[AudioStreamMP3]

@onready var nav_agent = $NavigationAgent3D
var SPEED = 10

@onready var barrel = $Barrel
@onready var mouth = $Mouth
@onready var right_eye : RayCast3D = $"Right eye"
@onready var left_eye : RayCast3D = $"Left eye"
@onready var hand = $Hand


var can_do_lil_darel = true

@onready var game = get_parent()

var previous_health = health

var is_phase_2 = false
var is_actual_phase_2 = false

var stunned = false
@onready var transition_dialog = $transition_dialog

func _ready():
	transition_dialog.playback_finished.connect(start_phase_2)

func _process(_delta):
	
	if Game.game_started == false:
		return
	
	if GlobalVars.is_bossfight == false:
		return
	
	if previous_health > health:
		
		if health <= 80:
			if !is_phase_2:
				var darel = LIL_DAREL.instantiate()
				
				get_parent().add_child(darel)
				
				darel.global_position = mouth.global_position
	
	previous_health = health
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	if !player: return
	
	var dst = global_position.distance_to(player.global_position)
	if dst < 90:
		lil_darel_attack(1)
	
	if get_tree().get_nodes_in_group("lil darel").size() > 20:
		can_do_lil_darel = false
	
	health = clampf(health,0.0,100.0)
	
	cloroxes_damage()
	
	if health <= 0:
		if !is_phase_2:
			transition_to_phase_2()
	
	if is_actual_phase_2 and not stunned:
		update_target_location(player.global_position)
		pathfinding()

func pathfinding():
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * SPEED
	
	velocity = new_velocity
	
	move_and_slide()

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location

func cloroxes_damage():
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		var required_dst = 50
		
		if is_phase_2:
			required_dst = 2
		
		if distance < required_dst:
			health -= 5
			clorox.queue_free()
			
			if is_phase_2:
				stunned = true
				$"phase 2 stun".start(2)
				shake(2,50,1)
				
				var stream = screams.pick_random()
				$scream.stream = stream
				$scream.play()
	
	if is_phase_2:
		for item in get_tree().get_nodes_in_group("dropped_item"):
			var dst = global_position.distance_to(item.global_position)
			if dst < 2:
				health -= 1
				item.queue_free()
	

func transition_to_phase_2():
	if is_phase_2: return
	
	$bigboom.play()
	$AudioStreamPlayer.stop()
	game.darel_phase2_transition()
	
	shake(3, 100, 5)
	
	for lil_darel in get_tree().get_nodes_in_group("lil darel"):
		lil_darel.queue_free()
	
	for darel_ball in get_tree().get_nodes_in_group("darel_ball"):
		darel_ball.queue_free()
	
	is_phase_2 = true
	
	for i in range(0,5):
		var big_explosion = BIGGER_EXPLOSION.instantiate()
		get_parent().add_child(big_explosion)
		big_explosion.global_position = global_position + Vector3(randf_range(-30,30),randf_range(-30,30),randf_range(-30,30))
		await Game.sleep(0.5)
	
	
	
	await Game.sleep(3)
	$transition_music.play()
	scale = Vector3(4,4,4)
	global_position.y = 2
	

	$transition_dialog.play_streams()
	#$transition_timer.start($transition_dialog.stream.get_length() / $transition_dialog.pitch_scale)
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	
	player.global_position = global_position
	player.global_position.x = global_position.x + 5


func start_phase_2():
	health = 100
	game.darel_phase2_start()
	is_actual_phase_2 = true
	$transition_dialog.stop()
	$transition_music.stop()
	$"phase 2 attack".start()
	
	GuiManager.show_tip("[color=green]Dariel 2nd phase[/color]\nAnother way to damage [b]Dariel[/b] is to [b]throw any item[/b] to him.", 7)

func lil_darel_attack(amount = 1):
	if !can_do_lil_darel: return
	if is_phase_2: return
	
	for i in range(0,amount):
		var darel = LIL_DAREL.instantiate()
		
		get_parent().add_child(darel)
		
		darel.global_position = mouth.global_position
	
	can_do_lil_darel = false


func _on_lil_darel_timeout_timeout():
	can_do_lil_darel = true

var force_magnitude: float = 100.0

func _on_darel_ball_timeout():
	if Game.game_started == false:
		return
	if GlobalVars.is_bossfight == false:
		return
	if is_phase_2: return
	
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	if !player: return
	
	var darel_ball = DAREL_BALL.instantiate()
	
	get_parent().add_child(darel_ball)
	
	var direction = player.global_position - barrel.global_position
	var impulse = direction.normalized() * force_magnitude
	
	darel_ball.global_position = barrel.global_position
	darel_ball.apply_central_impulse(impulse)
	
	if floor($ray.time_left) == 10:
		if !did_play_charge:
			$AudioStreamPlayer.play()
			did_play_charge = true

var did_play_charge = false

func ray_attack():
	if is_phase_2: return
	did_play_charge = false
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	if !player: return
	
	if Game.game_started == false:
		return
	if GlobalVars.is_bossfight == false:
		return
	
	var right_point = right_eye.global_position + Vector3(0,0,200)
	var left_point = left_eye.global_position + Vector3(0,0,200)
	
	if right_eye.get_collider():
		right_point = right_eye.get_collision_point()
	
	if left_eye.get_collider():
		left_point = left_eye.get_collision_point()
	
	var ray1 = DAREL_RAY.instantiate()
	var ray2 = DAREL_RAY.instantiate()
	
	get_parent().add_child(ray1)
	get_parent().add_child(ray2)
	
	
	var right_curve : Curve3D = Curve3D.new()
	right_curve.add_point(right_eye.global_position)
	right_curve.add_point(right_point)
	
	var left_curve : Curve3D = Curve3D.new()
	left_curve.add_point(left_eye.global_position)
	left_curve.add_point(left_point)
	
	ray1.curve = right_curve
	ray2.curve = left_curve
	
	ray1.set_curve()
	ray2.set_curve()
	
	var explosion1 = EXPLOSION.instantiate()
	var explosion2 = EXPLOSION.instantiate()
	
	get_parent().add_child(explosion1)
	get_parent().add_child(explosion2)
	
	explosion1.global_position = right_point
	explosion2.global_position = left_point
	
	await Game.sleep(0.25)
	if right_point.distance_to(player.global_position) < 4:
		player.die("darel")
	elif left_point.distance_to(player.global_position) < 4:
		player.die("darel")
	
	await Game.sleep(5)
	
	explosion1.queue_free()
	explosion2.queue_free()
	
	ray1.queue_free()
	ray2.queue_free()

const ATTACKS = {
	"clorox" : 25,
	"lildarel" : 10
}

func _on_phase_2_attack_timeout():
	if stunned: return
	
	var attack = pick_random_weighted(ATTACKS)
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	if !player: return
	
	if attack == "clorox":
		var clorox = load("res://Clorox Wipes.tscn").instantiate()
		
		clorox.auto_aim = true
		clorox.auto_aim_node = self
		clorox.auto_aim_capture_node = player
		clorox.stop_timer = true
		clorox.is_evil = true
		clorox.SPEED = 20
		
		get_parent().add_child(clorox)
		
		clorox.global_position = player.global_position + Vector3(randf_range(10,20),randf_range(10,20),randf_range(10,20))
		clorox.look_at(global_position)
		clorox.add_to_group("evil_wipes")
		
		play_sound_with_subtitle(GETOVER,"GET OVER HERE")
		
	elif attack == "lildarel":
		for i in range(0,5):
			await Game.sleep(0.1)
			
			var darel = LIL_DAREL.instantiate()
			darel.SPEED = 5
			get_parent().add_child(darel)
			
			darel.global_position = global_position + Vector3(randf_range(-5,5),10,randf_range(-5,5))
		
		play_sound_with_subtitle(FULLER,"Fuller auto")

func play_sound_with_subtitle(stream,subtitle):
	var audio := AudioStreamPlayer3D.new()
	audio.stream = stream
	
	add_child(audio)
	audio.play()
	GuiManager.show_subtitle(subtitle,stream)
	
	await Game.sleep(stream.get_length())
	audio.queue_free()

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

func _on_phase_2_stun_timeout():
	stunned = false

func shake(time_sec = 1.0, speed = 10.0, strength = 5.0, do_static = true):
	
	var initial_pos = global_position
	
	var timer = 0.0
	while timer < time_sec:
		if !do_static:
			global_position += Vector3(randf_range(-strength, strength), randf_range(-strength, strength), randf_range(-strength, strength))
		else:
			global_position = initial_pos + Vector3(randf_range(-strength, strength), randf_range(-strength, strength), randf_range(-strength, strength))
		await Game.sleep(1.0 / speed)
		timer += 1.0 / speed
	if do_static:
		global_position = initial_pos
