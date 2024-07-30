extends Node3D

@export var can_slowdown = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	if multiplayer.is_server():
		can_slowdown = true
