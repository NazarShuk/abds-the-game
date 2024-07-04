extends SubViewport

var target_position = Vector3(0,19.991,-33.775)
var speed: float = 200.0  # Adjust the speed as needed

# Easing function parameters
var move_time: float = 20.0  # Time it takes to move to the target
var elapsed_time: float = 0.0  # Elapsed time since start of movement
var start_position: Vector3  # Starting position


func _process(delta):
	if elapsed_time < move_time:
		elapsed_time += delta
		var t = clamp(elapsed_time / move_time, 0.0, 1.0)
		var eased_t = ease_in_out(t)
		$Camera3D.global_position = start_position.lerp(target_position, eased_t)

func _on_timer_timeout():
	start_position = $Camera3D.global_position
	target_position = Vector3(randf_range(-90,140),randf_range(10,20),randf_range(-200,-50))
	elapsed_time = 0.0
func ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
