extends Teacher
class_name EvilNeil

func _ready() -> void:
	Game.on_book_collected.connect(_on_book_collected)

func _on_book_collected(amount):
	if multiplayer.is_server():
		var players_in_lobby = Game.players.keys().size()
		if players_in_lobby > 1:
			DEFAULT_SPEED += (0.5 * (players_in_lobby / 2.0)) * amount
		else:
			DEFAULT_SPEED += 0.5 * amount

func _physics_process(delta: float) -> void:
	super(delta)
	
	ai(delta)

func ai(delta):
	if !Game.game_started or !multiplayer.is_server(): return
	
	var closest = null
	var closest_distance = INF
	var closest_player = null
	
	for p in Game.players.keys():
		if !Game.players[p].is_dead:
			var player = Game.get_player_by_id(p)
			if !player: continue
			var distance = global_position.distance_to(player.global_position)
		
			if distance < closest_distance:
				closest = player.global_position
				closest_distance = distance
				closest_player = player
	
	if closest:
		target_player = closest_player
		update_target_location(closest)
		
	else:
		target_player = null
