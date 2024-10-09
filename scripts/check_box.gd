extends ColorRect

@export var param_name : String
@export var label_text : String
@onready var check_button = $CheckButton

var did_set = false

func _ready():
	check_button.button_pressed = Game.game_params.get_param(param_name)
	Game.on_customization_reset.connect(_on_reset)
	check_button.text = label_text
	did_set = true

func _on_check_button_toggled(toggled_on):
	if !multiplayer.is_server(): return
	if did_set == false: return
	
	Game.set_customization.rpc(param_name, toggled_on)

func _on_reset():
	check_button.button_pressed = Game.game_params.get_param(param_name)
