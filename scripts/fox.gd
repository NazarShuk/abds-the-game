extends Teacher

const DROPPED_MTNDEW = preload("res://dropped_mtndew.tscn")

@onready var unstucker = $Unstucker
@export var mute : bool

var initial_pos = Vector3.ZERO

var notebooks_left = 0

func _ready():
	super._ready()
	
	initial_pos = global_position
	Game.on_book_collected.connect(_on_book_collected)
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("mr_fox"):
		queue_free()

func _on_book_collected(amount):
	if !multiplayer.is_server(): return
	
	if amount > 0:
		if notebooks_left > 0:
			notebooks_left -= 1

func _physics_process(_delta):
	super._physics_process(_delta)
	
	if mute:
		$AudioStreamPlayer3D.volume_db = -80
	else:
		$AudioStreamPlayer3D.volume_db = 8.602
	
	if multiplayer.is_server():
		speed_multiplier = 1 - (notebooks_left / 10)
		
		unstucker.do_penalties = notebooks_left > 0
		
		if notebooks_left > 0:
			var book = Game.get_closest_node_in_group(global_position,"Book")
			
			if book:
				update_target_location(book.global_position)
			else:
				update_target_location(initial_pos)
		else:
				update_target_location(initial_pos)

@rpc("any_peer","call_local")
func mr_fox_collect(amount : int):
	if multiplayer.is_server():
		if notebooks_left + amount >= 10:
			for i in range(0, notebooks_left + amount):
				var mtndew = DROPPED_MTNDEW.instantiate()
				get_parent().add_child(mtndew,true)
				mtndew.global_position = global_position
			
			notebooks_left = 0
		else:
			notebooks_left += amount
			Game.info_text("Follow Mr.Fox to find " + str(notebooks_left) + " notebooks!")

func calculate_multiplier(number: float, max_multiplier: float, scaling_factor = 100.0) -> float:
	return max_multiplier / (1.0 + number / scaling_factor)
