extends CharacterBody3D

@export var health = 100

const LIL_DAREL = preload("res://lil_darel.tscn")
const DAREL_BALL = preload("res://darel_ball.tscn")
const DAREL_RAY = preload("res://darel ray.tscn")

@onready var barrel = $Barrel
@onready var mouth = $Mouth
@onready var right_eye : RayCast3D = $"Right eye"
@onready var left_eye : RayCast3D = $"Left eye"

var can_do_lil_darel = true

@onready var game = get_parent()

var previous_health = health

func _process(delta):
	
	if game.game_started == false:
		return
	
	if Allsingleton.is_bossfight == false:
		return
	
	if previous_health > health:
		
		if health <= 80:
			var darel = LIL_DAREL.instantiate()
			
			get_parent().add_child(darel)
			
			darel.global_position = mouth.global_position
			
			ray_attack()
	
	previous_health = health
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	if !player: return
	
	var dst = global_position.distance_to(player.global_position)
	
	if dst < 90:
		lil_darel_attack(1)
	
	if get_tree().get_nodes_in_group("lil darel").size() > 20:
		can_do_lil_darel = false
	
	health = clampf(health,0.0,100.0)
	
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		if distance < 50:
			health -= 5
			clorox.queue_free()


func lil_darel_attack(amount = 1):
	if !can_do_lil_darel: return
	
	
	for i in range(0,amount):
		var darel = LIL_DAREL.instantiate()
		
		get_parent().add_child(darel)
		
		darel.global_position = mouth.global_position
	
	can_do_lil_darel = false


func _on_lil_darel_timeout_timeout():
	can_do_lil_darel = true

var force_magnitude: float = 100.0

func _on_darel_ball_timeout():
	if game.game_started == false:
		return
	if Allsingleton.is_bossfight == false:
		return
	
	var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
	if !player: return
	
	var darel_ball = DAREL_BALL.instantiate()
	
	get_parent().add_child(darel_ball)
	
	var direction = player.global_position - barrel.global_position
	var impulse = direction.normalized() * force_magnitude
	
	darel_ball.global_position = barrel.global_position
	darel_ball.apply_central_impulse(impulse)

func ray_attack():
	
	var right_point = right_eye.global_position + Vector3(0,0,-200)
	var left_point = left_eye.global_position + Vector3(0,0,-200)
	
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
