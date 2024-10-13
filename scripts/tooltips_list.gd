extends ScrollContainer

@export var tooltip_ui : PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for tooltip in GuiManager.saved_tips.values():
		var tui : RichTextLabel = tooltip_ui.instantiate()
		tui.text = tooltip
		$VBoxContainer.add_child(tui)
