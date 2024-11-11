extends ColorRect

@export_category("Parameter")
@export var param_name : String
@export var label_text : String

@export_category("Value")
@export var max_val : float
@export var min_val : float


func _ready():
	$Label.text = " " + label_text
	$LineEdit.text = str(Game.game_params.get_param(param_name))
	Game.on_customization_reset.connect(_on_reset)

func _on_reset():
	$LineEdit.text = str(Game.game_params.get_param(param_name))

func _on_line_edit_text_changed(new_text):
	var val = new_text.to_float()
	var caret_column =  $LineEdit.caret_column
	if val > max_val:
		$LineEdit.text = str(max_val)
		val = max_val
	if val < min_val && len(new_text) > 0:
		$LineEdit.text = str(min_val)
		val = min_val
	$LineEdit.caret_column = caret_column
	
	Game.set_customization.rpc(param_name,$LineEdit.text.to_float())
