extends Area3D

@export var speed : float = 5

func _process(delta: float) -> void:
	translate(Vector3(0,0,-speed * delta))


func _on_timer_timeout() -> void:
	queue_free()
