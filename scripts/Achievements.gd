extends Node

const FILE_PATH = "user://achievements.save"

var achievements = {}

var picked_skin = 0

var books_collected = 0
var deaths = 0

enum Quest_type {
	BOOK_COLLECT,
	SHOP_CREDITS,
	PACER_LAPS,
	WALK_METERS,
	
	
	NONE = -1 # quest not loaded in
}



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
		
		if !achievements.has("bossfight_spared"):
			achievements["bossfight_spared"] = false
			save_all()
		
		if !achievements.has("bossfight_killed"):
			achievements["bossfight_killed"] = false
			save_all()

func check_achievement(achievement_name):
	if achievements.has(achievement_name):
		return achievements[achievement_name]

func set_val(val_name,val):
	
	if !achievements.has(val_name):
		show_achievement(val_name)
	
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

func show_achievement(text : String):
	$AnimationPlayer.play("show")
	
	var formatted_text = text.replace("_"," ")
	formatted_text = text.capitalize()
	
	$Achievement/MarginContainer/Panel/Label2.text = formatted_text

func _exit_tree() -> void:
	save_all()
