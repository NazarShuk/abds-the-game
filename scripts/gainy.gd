extends Teacher

@onready var unstucker = $Unstucker

var init_pos : Vector3

@export var angered = false

func _ready():
	super._ready()
	
	init_pos = global_position
	Game.on_pre_game_started.connect(_on_pregame_started)
	Game.on_book_collected.connect(_on_book_collected)

func _on_pregame_started():
	if !Game.game_params.get_param("ms_gainy"):
		queue_free()

func _on_book_collected(_amount):
	target_player = null

func _physics_process(_delta):
	super._physics_process(_delta)
	
	if multiplayer.is_server():
		angered = target_player != null
		unstucker.do_penalties = angered
		
		if target_player:
			
			if Game.players.has(target_player.name.to_int()):
				var player = Game.players[target_player.name.to_int()]
				if player.is_dead:
					target_player = null
			
			if target_player:
				update_target_location(target_player.global_position)
		else:
			go_back()

func go_back():
	update_target_location(init_pos)

func _on_timer_timeout():
	if multiplayer.is_server():
		if Game.game_started:
			if randi_range(0,20) != 1: return
			attack_someone()

func attack_someone():
	if multiplayer.is_server():
		if Game.game_started:
			var just_a_chill_guy = get_tree().get_nodes_in_group("player").pick_random()
			
			if just_a_chill_guy:
				target_player = just_a_chill_guy
				Game.info_text("Ms.Gainy is angry at " + just_a_chill_guy.steam_name)

func _on_gainy_area_entered(area):
	if area.is_in_group("player_area"):
		if target_player:
			if area.get_parent().name == target_player.name:
				target_player = null
