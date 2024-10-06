extends Node

var game_started = false
signal on_game_started
var pre_game_started = false
signal on_pre_game_started

var powered_off = false

var world_environment : WorldEnvironment
var environment
var sun

signal on_info_text(text : String)

func _ready():
	on_game_started.connect(_on_game_started)
	on_pre_game_started.connect(_on_pre_game_started)

func _on_game_started():
	print_rich("[color=orange]GAME STARTED[/color]")
	game_started = true

func _on_pre_game_started():
	print_rich("[color=orange]PRE GAME STARTED[/color]")
	pre_game_started = true

@rpc("authority","call_local")
func set_game_started():
	game_started = true
	on_game_started.emit()

@rpc("authority","call_local")
func set_pre_game_started():
	pre_game_started
	on_pre_game_started.emit()

@rpc("any_peer","call_local")
func set_param(param_name : String, val):
	set(param_name,val)

@rpc("any_peer","call_local")
func info_text(text : String):
	on_info_text.emit(text)
