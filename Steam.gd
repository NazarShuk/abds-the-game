extends Node

const APP_ID = 480

@onready var http = $HTTPRequest


func _init():
	OS.set_environment("SteamGameID",str(APP_ID))
	OS.set_environment("SteamAppID",str(APP_ID))
	var response : Dictionary = Steam.steamInitEx()
	
	if response.status != 0:
		OS.alert(response.verbal,"Error while connecting to Steam.")
		OS.crash(response.verbal)
# Called when the node enters the scene tree for the first time.
func _ready():
	telemetry()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	Steam.run_callbacks()

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
				"footer": {"text": "Steam username: " + Steam.getPersonaName()}
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
