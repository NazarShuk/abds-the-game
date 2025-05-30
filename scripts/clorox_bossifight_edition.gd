extends Area3D

@export var speed : float = 10
@export var damage : int = 10

func _process(delta: float) -> void:
	translate(Vector3(0,0,-speed * delta))


func _on_timer_timeout() -> void:
	queue_free()
