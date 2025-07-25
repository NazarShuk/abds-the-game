extends Node2D

@export var skin_list : ItemList
@export var achievement_list : VBoxContainer

func _ready():
	for achievement in Achievements.achievements:
		if Achievements.achievements[achievement] == true:
			var label = Label.new()
			label.text = achievement.replace("_"," ")
			if label.text == "freaky ending":
				label.text = "𝓯𝓻𝓮𝓪𝓴𝔂 ending"
			label.add_theme_color_override("font_color",Color.BLACK)
			label.add_theme_font_override("font",load("res://fonts/Ldfcomicsans-jj7l.ttf"))
			label.add_theme_font_size_override("font_size",32)
			
			achievement_list.add_child(label)
	
	$CanvasLayer/Label2.text = str(Achievements.books_collected) + " books collected"
	$CanvasLayer/Label3.text = str(Achievements.deaths) + " times died" 
	
	$visual_body.skin = Achievements.picked_skin
	
	if Achievements.achievements.has("freaky_ending") == false:
		skin_list.set_item_disabled(1,true)
	if Achievements.achievements.has("perfect_ending") == false:
		skin_list.set_item_disabled(2,true)
	if Achievements.achievements.has("impossible_ending") == false:
		skin_list.set_item_disabled(3,true)
	if Achievements.achievements.has("disoriented_ending") == false:
		skin_list.set_item_disabled(4,true)
	if Achievements.achievements.has("leahy_time_p rank") == false:
		skin_list.set_item_disabled(5,true)
	
	if Achievements.achievements.get("bossfight_spared", false) == true:
		skin_list.add_item("Darel.png")

func _on_button_pressed():
	get_tree().change_scene_to_file.call_deferred("res://scenes/logos.tscn")

func _on_item_list_item_selected(index):
	Achievements.picked_skin = index
	Achievements.save_all()
	
	$visual_body.skin = index
