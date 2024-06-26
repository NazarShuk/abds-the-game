extends Node

const FILE_PATH = "user://achievements.save"

var achievements = {
	"perfect_ending":false,
	"impossible_ending":false,
	"freaky_ending":false,
	"bad_ending":false,
	"good_ending":false,
	"10_deaths":false,
	"30_deaths":false,
	"50_deaths":false,
	"100_deaths":false,
	"10_books":false,
	"30_books":false,
	"50_books":false,
	"100_books":false
}

var books_collected = 0
var deaths = 0

func _ready():
	if FileAccess.file_exists(FILE_PATH):
		var game_save = FileAccess.open(FILE_PATH,FileAccess.READ)
		
		achievements = game_save.get_var()
		books_collected = game_save.get_var()
		deaths = game_save.get_var()

func check(name):
	return achievements[name]

func set_val(name,val):
	achievements[name] = val
	
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
	game_save.close()
