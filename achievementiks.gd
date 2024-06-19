extends Node2D

func _ready():
	for achievement in Achievements.achievements:
		print(achievement)
		if Achievements.achievements[achievement] == true:
			var label = Label.new()
			label.text = achievement.replace("_"," ")
			if label.text == "freaky ending":
				label.text = "𝓯𝓻𝓮𝓪𝓴𝔂 ending"
			label.add_theme_color_override("font_color",Color.BLACK)
			label.add_theme_font_override("font",load("res://Ldfcomicsans-jj7l.ttf"))
			label.add_theme_font_size_override("font_size",32)
			
			$CanvasLayer/ScrollContainer/VBoxContainer.add_child(label)
			
			
	$CanvasLayer/Label2.text = str(Achievements.books_collected) + " books collected"
	$CanvasLayer/Label3.text = str(Achievements.deaths) + " times died"


func _on_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")
