extends ColorRect

@export var game : Node3D
@export var param_name : String
@export var label_text : String
@export var is_disabled : bool
@export var if_enabled_harder : bool
@export var invert : bool


var initial_state : bool

func _ready():
	$CheckButton.text = label_text
	if !invert:
		$CheckButton.button_pressed = game.get(param_name)
	else:
		$CheckButton.button_pressed = !game.get(param_name)
		
	initial_state = $CheckButton.button_pressed
	
func _process(_delta):
	$CheckButton.disabled = is_disabled

func _on_check_button_toggled(toggled_on):
	if !invert:
		game.set(param_name,str(toggled_on))
	else:
		game.set(param_name,str(!toggled_on))

func go_to_inital():
	$CheckButton.button_pressed = initial_state

func get_da_val():
	if !invert:
		return $CheckButton.button_pressed
	else:
		return !$CheckButton.button_pressed
