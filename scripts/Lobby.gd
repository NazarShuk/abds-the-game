extends Control

var default_params = GameParams.new()

var changed_params = false
@onready var game_config_client = $Label4/gameConfigClient

func _process(_delta):
	if !Game.pre_game_started:
		var affect_difficulty = 0
		
		game_config_client.text = ""
		
		for property in default_params.get_property_list():
			if property.name.begins_with("param_"):
				var default_value = default_params.get(property.name)
				var current_value = Game.game_params.get(property.name)
				
				if default_value != current_value:
					game_config_client.text += format_param_name(property.name) + ": " + str(current_value) + "\n"
					
					if current_value is bool:
						if not default_params.neutral_parameters.has(property.name):
								affect_difficulty += 1
					elif current_value is float or current_value is int:
						if current_value < default_value and not default_params.lower_is_harder.has(property.name):
							affect_difficulty += 1
						elif current_value > default_value and not default_params.higher_is_harder.has(property.name):
							affect_difficulty += 1
		
		changed_params = affect_difficulty > 0
		$achievement.visible = changed_params

func format_param_name(param_name):
	var formatted_name : String = param_name.replace("_"," ")
	formatted_name = formatted_name.replace("param ","")
	formatted_name = formatted_name.capitalize()
	return formatted_name


func _on_reset_to_default_pressed():
	Game.clear_customization.rpc()
