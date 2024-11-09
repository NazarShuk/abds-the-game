extends Node3D

@export var strength_left = 10

@export var can_pickup = false
@export var can_break = true

var shake = false
var shake_strength = 0.1
@onready var initial_pos = global_position

func _process(_delta: float) -> void:
	if shake:
		global_position = initial_pos + Vector3(randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength))
	
	
@rpc("any_peer","call_local")
func play():
	$CPUParticles3D.emitting = true
	shake = true
	await Game.sleep(0.1)
	shake = false
	global_position = initial_pos

@rpc("any_peer","call_local")
func break_glass_sound(big):
	if big:
		$big.play()
	else:
		$small.play()
@rpc("any_peer","call_local")
func break_glass():
	if multiplayer.is_server():
		
		if can_break:
			if strength_left > 0:
				strength_left -= 1
				
				break_glass_sound.rpc(false)
				play.rpc()
			else:
				break_glass_sound.rpc(true)
				play.rpc()
				$MeshInstance3D6.hide()
				$"Fire Extinguisher".hide()
				can_pickup = true
				can_break = false
		else:
			can_pickup = false
			await Game.sleep(20)
			$MeshInstance3D6.show()
			$"Fire Extinguisher".show()
			strength_left = 10
			can_break = true
