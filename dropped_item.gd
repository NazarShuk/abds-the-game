extends RigidBody3D

@export var item = -1
@export var is_expired = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_timer_timeout():
	if multiplayer.is_server():
		is_expired = true
		get_parent().expired_items.append(get_path())
		print("expired")

func _exit_tree():
	if multiplayer.is_server():
		get_parent().expired_items.remove_at(get_parent().expired_items.find(get_path()))
