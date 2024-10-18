extends Node

const APP_ID = 480

var steam_api : Object = null

@onready var http = $HTTPRequest
var steam_name = ""



func _init():
	if Engine.has_singleton("Steam"):
		steam_api = Engine.get_singleton("Steam")
		
		OS.set_environment("SteamGameID",str(APP_ID))
		OS.set_environment("SteamAppID",str(APP_ID))
		var response : Dictionary = steam_api.steamInitEx()
		
		if response.status != 0:
			Game.no_steam = true
			steam_name = OS.get_environment("USERNAME")
		else:
			steam_name = steam_api.getPersonaName()
		
		print("steam init with response: ",response)

# Called when the node enters the scene tree for the first time.
func _ready():
	if !OS.has_feature("debug"):
		telemetry()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !Game.no_steam:
		steam_api.run_callbacks()

func telemetry():
	# some telemetry so i know who is pplyiong
	
	var body = {
		"content": "",
		"tts": false,
		"embeds":
		[
			{
				"id": 764355288,
				"title": "Game opened",
				"color": 16711680,
				"footer": {"text": "Username: " + steam_name}
			}
		],
		"components": [],
		"actions": {},
		"username": "Telemetry"	}

	http.request(
		"https://discord.com/api/webhooks/1259565384902770741/zxE7W7I16ylutLlvMCh4qVz7Fz08N4bfrvpGdxIsT7hdXFFptZ_FSjRMmMnrnhYjkqXd",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
