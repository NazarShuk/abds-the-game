extends Node3D

@export var strength_left = 10

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
		if strength_left > 1:
			play.rpc()
			strength_left -= 1
			break_glass_sound.rpc(false)
			can_break = false
		else:
			strength_left = 10
			break_glass_sound.rpc(true)
			can_break = false
			$Timer.paused = true
			$MeshInstance3D6.hide()
			$"Fire Extinguisher".hide()
			await get_tree().create_timer(20).timeout
			can_break = true
			$Timer.paused = false
			$MeshInstance3D6.show()
			$"Fire Extinguisher".show()
	


func _on_timer_timeout():
	can_break = true
