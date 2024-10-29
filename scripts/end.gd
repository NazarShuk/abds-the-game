extends Node3D


@export var died_text : Label
@export var collected_text : Label
@export var achievement_name : String

func _ready():
	GuiManager.reset_cursor()
	GuiManager.force_cursor_state(true)
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	AudioServer.set_bus_solo(6,false)
	
	died_text.text = "you died " + str(GlobalVars.deaths) + " times"
	collected_text.text = "and collected " + str(GlobalVars.books_collected) + " notebooks"
	
	Achievements.set_val(achievement_name,true)
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	

func _exit_tree() -> void:
	GuiManager.force_cursor_state(false)
	GuiManager.reset_cursor()

func _on_timer_timeout():
	get_tree().change_scene_to_file.call_deferred("res://logos.tscn")

func _input(_event):
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file.call_deferred("res://logos.tscn")

func submit_to_leaderboard():
	if OS.has_feature("debug"): return
	
	var http = HTTPRequest.new()
	http.timeout = 5
	add_child(http)
	
	var books = Achievements.books_collected
	
	http.request_completed.connect(_on_post_request_completed)
	http.request(GlobalVars.api_url + "?username=" + SteamManager.steam_name + "&books=" + str(books),["User-Agent: insomnia/9.3.2","Accept: /*/","Content-Length: 0"],HTTPClient.METHOD_POST)

func _on_post_request_completed(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
	if result == 0:
		print("set books cool")
	else:
		print("error", result)
