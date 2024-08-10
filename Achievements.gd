extends Node

const FILE_PATH = "user://achievements.save"

var achievements = {
	"freaky_ending":false,
	"perfect_ending":false,
	"impossible_ending":false,
	"disoriented_ending": false,
	"bad_ending":false,
	"good_ending":false,
}

var picked_skin = 0

var books_collected = 0
var deaths = 0

func _ready():
	if FileAccess.file_exists(FILE_PATH):
		var game_save = FileAccess.open(FILE_PATH,FileAccess.READ)
		
		var ach = achievements
		
		achievements = game_save.get_var()
		if !typeof(achievements) == TYPE_DICTIONARY:
			achievements = ach
		
		
		books_collected = game_save.get_var()
		deaths = game_save.get_var()
		picked_skin = game_save.get_var()
		if !picked_skin:
			picked_skin = 0
		
		if !achievements.has("disoriented_ending"):
			achievements["disoriented_ending"] = false
			save_all()

func check_achievement(achievement_name):
	return achievements[achievement_name]

func set_val(val_name,val):
	achievements[val_name] = val
	
	var game_save = FileAccess.open(FILE_PATH,FileAccess.WRITE)
	
	game_save.store_var(achievements)
	game_save.store_var(deaths)
	game_save.store_var(books_collected)
	game_save.close()
	
func save_all():
	var game_save = FileAccess.open(FILE_PATH,FileAccess.WRITE)
	
	game_save.store_var(achievements)
	game_save.store_var(deaths)
	game_save.store_var(books_collected)
	game_save.store_var(picked_skin)
	game_save.close()
