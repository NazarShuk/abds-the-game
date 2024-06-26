extends Node

const APP_ID = 480

func _init():
	OS.set_environment("SteamGameID",str(APP_ID))
	OS.set_environment("SteamAppID",str(APP_ID))
	var response : Dictionary = Steam.steamInitEx()
	
	if response.status != 0:
		OS.alert(response.verbal,"Error while connecting to Steam.")
		OS.crash(response.verbal)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	Steam.run_callbacks()
	
