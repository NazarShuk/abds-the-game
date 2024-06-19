extends Node

const APP_ID = 480

# Called when the node enters the scene tree for the first time.
func _ready():
	print(OS.get_name())
	OS.set_environment("SteamGameID",str(APP_ID))
	OS.set_environment("SteamAppID",str(APP_ID))
	var response : Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % response)
	
	if response.status != 0:
		if response.status == 2:
			Allsingleton.steam_error = "Steam is probably not open."
		else:
			Allsingleton.steam_error = response.verbal
		Allsingleton.steam_error_code = response.status
		
		get_tree().change_scene_to_file("res://steaminitfailed.tscn")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	Steam.run_callbacks()

