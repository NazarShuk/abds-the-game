extends Panel

@export var player : CharacterBody3D
@export var hand : Node3D
@onready var h_box: HBoxContainer = $HBoxContainer

const ITEM_VISUALISER = preload("res://scenes/item_visualiser.tscn")

func _ready() -> void:
	for i in range(0,player.max_slots):
		var visualizer = ITEM_VISUALISER.instantiate()
		h_box.add_child(visualizer)

func _process(delta: float) -> void:
	for i in range(0,player.inventory.size()):
		if h_box.get_child(i):
			if player.selected_slot == i:
				h_box.get_child(i).select()
			else:
				h_box.get_child(i).unselect()

func _on_player_inventory_changed() -> void:
	for i in range(0,player.inventory.size()):
		var item_id = player.inventory[i]
		
		if h_box.get_child(i):
			if item_id != -1:
				var item_3d = hand.get_child(item_id).duplicate()
				item_3d.show()
				h_box.get_child(i).set_item(item_3d)
			else:
				h_box.get_child(i).set_item(Node.new())
