extends ColorRect

@export var game : Node3D
@export var param_name : String
@export var label_text : String
@export var is_disabled : bool

@export var max_val : float
@export var min_val : float

@export var is_neutral : bool

var initial_state

func _ready():
	$Label.text = " " + label_text
	$LineEdit.text = str(game.get(param_name))
	initial_state = $LineEdit.text
	
func _process(_delta):
	$LineEdit.editable = !is_disabled

func go_to_inital():
	$LineEdit.text = initial_state


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
	game.set(param_name, val)

func get_da_val():
	return $LineEdit.text.to_float()
