extends Control

var default_params = GameParams.new()

var changed_params = false
@onready var game_config_client = $Label4/gameConfigClient

func _process(_delta):
	if !Game.pre_game_started:
		var changed = 0
		
		game_config_client.text = ""
		
		for property in default_params.get_property_list():
			if property.name.begins_with("param_"):
				if default_params.get(property.name) != Game.game_params.get(property.name) and not default_params.neutral_parameters.has(property.name):
					changed += 1
					
					var formatted_name : String = property.name.replace("_"," ")
					formatted_name = formatted_name.replace("param ","")
					formatted_name = formatted_name.capitalize()
					
					game_config_client.text += formatted_name + ": " + str(Game.game_params.get(property.name)) + "\n"
		
		changed_params = changed > 0
		$achievement.visible = changed_params


func _on_reset_to_default_pressed():
	Game.clear_customization.rpc()
