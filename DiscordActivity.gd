extends Node

var game_started = false
var pre_started_game = false
var is_in_lobby = false
var players_in_lobby = 0

var time_started

@onready var game = $".."


func _ready():
	DiscordRPC.app_id = 1260449832154435596
	DiscordRPC.details = "In the Menu"
	DiscordRPC.state = "Idle"
	DiscordRPC.large_image = "ela_book"
	DiscordRPC.large_image_text = "Cool"
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	
	DiscordRPC.refresh()

var previous_game_started = false

func _process(delta):
	if !is_multiplayer_authority(): return
	
	game_started = game.game_started
	if previous_game_started != game_started:
		time_started = int(Time.get_unix_time_from_system())
	previous_game_started = game_started
	
	pre_started_game = game.pre_started_game
	is_in_lobby = game.is_in_lobby
	players_in_lobby = game.players_in_lobby
	

func _on_discord_timeout():
	if !is_multiplayer_authority(): return
	
	if game_started:
		DiscordRPC.details = $"../CanvasLayer/Main/CollectedBooksLabel".text
		DiscordRPC.state = "Playing"
		DiscordRPC.current_party_size = game.players_in_lobby
		DiscordRPC.max_party_size = 32
		if time_started:
			DiscordRPC.start_timestamp = time_started
	elif pre_started_game:
		DiscordRPC.details = "Finding the notebook"
		DiscordRPC.state = "Playing"
		DiscordRPC.current_party_size = game.players_in_lobby
		DiscordRPC.max_party_size = 32
	elif is_in_lobby:
		DiscordRPC.details = "In lobby"
		DiscordRPC.state = "Waiting"
		DiscordRPC.current_party_size = game.players_in_lobby
		DiscordRPC.max_party_size = 32
	else:
		DiscordRPC.details = "In the Menu"
		DiscordRPC.state = "Idle"
	DiscordRPC.refresh()

func _exit_tree():
	DiscordRPC.clear()
