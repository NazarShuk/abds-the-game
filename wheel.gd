extends Node3D

@onready var cylinder = $Cylinder

@export var game : Node3D

var rotate_speed = 1.0
var target_speed = 1.0

var is_idle = true
var can_spin = true
var target_rot = -1

var rewards = [
	{
		"name":"Fruit Snacks",
		"from":0,
		"to":30
	},
	{
		"name":"Pizza",
		"from":30,
		"to":60
	},
	{
		"name":"Mtn Dew",
		"from":60,
		"to":90
	},
	{
		"name":"Sunkist",
		"from":90,
		"to":120
	},
	{
		"name":"Sonic Gummy",
		"from":120,
		"to":150
	},
	{
		"name":"Ms Gainy attack",
		"from":150,
		"to":180
	},
	{
		"name":"Loose a notebook",
		"from":180,
		"to":210
	},
	{
		"name":"Rubber ducky",
		"from":210,
		"to":240
	},
	{
		"name": "Mr misuraca took a day off",
		"from":240,
		"to":270
	},
	{
		"name": "Pee pee",
		"from":270,
		"to": 300
	},
	{
		"name": "Nothing",
		"from":300,
		"to": 330
	},
	{
		"name": "Nothing",
		"from":330,
		"to": 360
	}
]


func _process(delta):
	if multiplayer.is_server():
		target_speed = lerp(float(target_speed), float(rotate_speed), 0.1)
		
		if is_idle:
			cylinder.rotate(Vector3(1,0,0),target_speed * delta)
		else:
			if cylinder.rotation_degrees.x < target_rot:
				cylinder.rotate(Vector3(1,0,0),target_speed * delta)

@rpc("any_peer","call_local")
func spin():
	if !multiplayer.is_server(): return
	if !is_idle: return
	if !can_spin: return
	
	var target_reward = rewards.pick_random()
	var target_rotation = randf_range(target_reward.from,target_reward.to)
	rotate_speed = 20
	can_spin = false
	await get_tree().create_timer(5).timeout
	
	rotate_speed = 0
	rotate_speed = 0
	rotate_speed = 0
	is_idle = false
	
	cylinder.rotation_degrees.x = target_rotation
	print(target_reward.name)
	give_reward(target_reward.name)
	
	await get_tree().create_timer(60).timeout
	rotate_speed = 1
	is_idle = true
	can_spin = true

func give_reward(what_name):
	if !multiplayer.is_server(): return
	play_cool_sound()
	game.info_text("Rolled " + what_name + "!")
	if what_name == "Fruit Snacks":
		game.give_item_to_everyone(0)
	elif what_name == "Pizza":
		game.give_item_to_everyone(2)
	elif what_name == "Mtn Dew":
		game.give_item_to_everyone(3)
	elif what_name == "Sunkist":
		game.give_item_to_everyone(5)
	elif what_name == "Sonic Gummy":
		game.give_item_to_everyone(10)
	elif what_name == "Ms Gainy attack":
		game.gainy_attack_func()
	elif what_name == "Loose a notebook":
		game.loose_notebooks(1)
	elif what_name == "Rubber ducky":
		game.give_item_to_everyone(4)
	elif what_name == "Mr misuraca took a day off":
		game.is_misuraca_disabled = true
	elif what_name == "Pee pee":
		for x in range(-10,10):
			for y in range(-10,10):
				var pos = Vector3(global_position.x + x, 0, global_position.z + y)
				game.spawn_puddle.rpc(pos)
	else:
		pass

@rpc("authority","call_local")
func play_cool_sound():
	$AudioStreamPlayer.play()
