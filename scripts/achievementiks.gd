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
			label.add_theme_font_override("font",load("res://Ldfcomicsans-jj7l.ttf"))
			label.add_theme_font_size_override("font_size",32)
			
			achievement_list.add_child(label)
	
	$CanvasLayer/Label2.text = str(Achievements.books_collected) + " books collected"
	$CanvasLayer/Label3.text = str(Achievements.deaths) + " times died" 
	
	$visual_body.pick_skin()
	
	if Achievements.achievements["freaky_ending"] == false:
		skin_list.set_item_disabled(1,true)
	if Achievements.achievements["perfect_ending"] == false:
		skin_list.set_item_disabled(2,true)
	if Achievements.achievements["impossible_ending"] == false:
		skin_list.set_item_disabled(3,true)
	if Achievements.achievements["disoriented_ending"] == false:
		skin_list.set_item_disabled(4,true)

func _on_button_pressed():
	get_tree().change_scene_to_file.call_deferred("res://logos.tscn")

func _on_item_list_item_selected(index):
	Achievements.picked_skin = index
	Achievements.save_all()
	
	$visual_body.pick_skin(index)
