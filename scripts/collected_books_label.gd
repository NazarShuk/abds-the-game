extends Label

@export var player : Player
var game_scene : GameScene

var _books_collected_in_team = 0
var _team = ""

func _ready() -> void:
	game_scene = player.get_parent()

func _process(_delta: float) -> void:
	
	if Game.game_started:
		if !game_scene.can_escape:
			if !game_scene.is_pacer:
				if not game_scene.competitive:
					
					var collected_books = str(Game.collected_books)
					
					if collected_books.split(".")[1] == "0":
						collected_books = collected_books.split(".")[0]
					
					text = collected_books + " books collected out of " + str(floori(Game.books_to_collect))
				else:
					
					get_books_collected_in_team(player.name.to_int())
					text = "Team %s\n%s books collected out of %s" % [_team, _books_collected_in_team, floori(Game.books_to_collect)]
					
				if game_scene.is_bet:
					text += "\nBet: " + str(game_scene.bet_books_left) + " left. Seconds left: " + str(floor(game_scene.get_node("Bet timer").time_left))
			else:
				text = "Pacer\nLap %s\nLevel %s" % [game_scene.pacer_lap, game_scene.pacer_level]
		else:
			if !game_scene.leahy_time:
				text = "Run."
			else:
				var collected_books = str(Game.collected_books)
				
				if collected_books.split(".")[1] == "0":
					collected_books = collected_books.split(".")[0]
				
				text = collected_books + " books collected out of " + str(floori(Game.books_to_collect))
	else:
		text = "Find an ELA book!"


@rpc("any_peer", "call_local", "unreliable")
func get_books_collected_in_team(peerid):
	if !multiplayer.is_server(): return
	if !Game.players.has(peerid): return
	
	var team = Game.players[peerid].team
	
	var total_books = 0
	for id in Game.players:
		if Game.players[id].team == team:
			total_books += Game.players[id].books_collected
		
	
	send_books_collected_in_team.rpc_id(peerid, total_books, team)
	
@rpc("any_peer", "call_local", "unreliable")
func send_books_collected_in_team(books_collected, team):
	_books_collected_in_team = books_collected
	_team = team
