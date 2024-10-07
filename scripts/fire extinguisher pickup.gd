extends Node3D

@export var strength_left = 10

@export var can_pickup = false

var can_break = true

@rpc("any_peer","call_local")
func play():
	$CPUParticles3D.emitting = true

@rpc("any_peer","call_local")
func break_glass_sound(big):
	if big:
		$big.play()
	else:
		$small.play()
@rpc("any_peer","call_local")
func break_glass():
	if multiplayer.is_server():
		if !can_break: return
		
		if !can_pickup:
			if strength_left > 0:
				strength_left -= 1
				can_break = false
				
				break_glass_sound.rpc(false)
				play.rpc()
			else:
				can_pickup = true
				break_glass_sound.rpc(true)
				play.rpc()
				$MeshInstance3D6.hide()
				$"Fire Extinguisher".hide()
		else:
			can_pickup = false
			can_break = false
			$Timer.stop()
			await Game.sleep(20)
			$MeshInstance3D6.show()
			$"Fire Extinguisher".show()
			strength_left = 10
			$Timer.start()
			


func _on_timer_timeout():
	if multiplayer.is_server():
		can_break = true
