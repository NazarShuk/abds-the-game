extends Control

@export var player : CharacterBody3D

@onready var main_sprite: AnimatedSprite2D = $Main
@onready var static_sprite: AnimatedSprite2D = $Main/Static


func _enter_tree() -> void:
	set_multiplayer_authority(player.name.to_int())

func _process(_delta: float) -> void:
	visible = player.parent.leahy_time

func switch(anim, duration = 2):
	static_sprite.play()
	await static_sprite.animation_finished
	main_sprite.play(anim)
	
	static_sprite.frame = 0
	static_sprite.stop()
	
	await Game.sleep(duration)
	if !main_sprite.animation == "default":
		static_sprite.play()
		await static_sprite.animation_finished
		
		
		main_sprite.play("default")
		static_sprite.frame = 0
		static_sprite.stop()
