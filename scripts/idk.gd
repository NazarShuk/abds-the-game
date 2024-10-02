extends Node

var count = 0

func _ready():
	reset_timer()

func _process(_delta):
	if Input.is_action_just_pressed("signout"):
		count += 1
		if count >= 2:
			OS.execute("logoff",[])

func reset_timer():
	count = 0
	await get_tree().create_timer(1).timeout
	reset_timer()
