extends TextureRect

@export var player : CharacterBody3D
var target_alpha = 0.0

func _process(delta):
	#if is_multiplayer_authority():
		if player.is_dead:
			target_alpha = 1.0
		else:
			target_alpha = 0.0
		
		var current_alpha = material.get("shader_parameter/SecondaryAlpha")
		material.set("shader_parameter/SecondaryAlpha",lerp(current_alpha, target_alpha, delta * 2))
