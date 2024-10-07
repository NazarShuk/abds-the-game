extends Node2D

@onready var default = $Player/Default
@onready var freaky = $Player/Freaky
@onready var perfect = $Player/Perfect
@onready var impossible = $Player/Impossible

@export var tooltip_ui : PackedScene

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
			
			$CanvasLayer/ScrollContainer/VBoxContainer.add_child(label)

	
	for tooltip in GuiManager.saved_tips.values():
		var tui : RichTextLabel = tooltip_ui.instantiate()
		tui.text = tooltip
		$CanvasLayer/Tooltips/VBoxContainer.add_child(tui)
	
	$CanvasLayer/Label2.text = str(Achievements.books_collected) + " books collected"
	$CanvasLayer/Label3.text = str(Achievements.deaths) + " times died" 
	
	var skins = $Player.get_children()
	for skin in skins:
		if skin is Node3D:
			skin.hide()
	
	
	
	if Achievements.achievements["freaky_ending"] == false:
		$CanvasLayer/ItemList.set_item_disabled(1,true)
	if Achievements.achievements["perfect_ending"] == false:
		$CanvasLayer/ItemList.set_item_disabled(2,true)
	if Achievements.achievements["impossible_ending"] == false:
		$CanvasLayer/ItemList.set_item_disabled(3,true)
	if Achievements.achievements["disoriented_ending"] == false:
		$CanvasLayer/ItemList.set_item_disabled(4,true)
	
	if Achievements.picked_skin == 4:
		$Player/Disoriented.show()
	if Achievements.picked_skin == 3:
		impossible.show()
	if Achievements.picked_skin == 2:
		perfect.show()
	if Achievements.picked_skin == 1:
		freaky.show()
	else:
		default.show()

func _on_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")

func _on_item_list_item_selected(index):
	var children = $Player.get_children()
	
	Achievements.picked_skin = index
	Achievements.save_all()
	
	for child in children:
		if child is Node3D:
			child.hide()
	
	children[index].show()
