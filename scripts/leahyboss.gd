extends Node3D

var target_pos = Vector3.ZERO
@export var do_shoot_clorox = false

const CLOROX_BOSSIFIGHT_EDITION = preload("res://scenes/clorox_bossifight_edition.tscn")

func _ready() -> void:
	clorox_action()

func _process(delta: float) -> void:
	$leahypng.global_position = lerp(global_position, target_pos, delta * 25)

func come_to_player():
	target_pos = get_tree().get_first_node_in_group("player").global_position

func clorox_action():
	await get_tree().create_timer(0.1, false).timeout
	if do_shoot_clorox:
		var clorox = CLOROX_BOSSIFIGHT_EDITION.instantiate()
		get_parent().add_child(clorox, true)
		clorox.global_position = $leahypng.global_position
		$leahypng.look_at($"../BossfightPlayer".global_position)
		clorox.global_rotation = $leahypng.global_rotation
	
	clorox_action()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
		
	const animations = [
		"spinny"
	]
	await get_tree().create_timer(1, false).timeout
	$AnimationPlayer.play(animations.pick_random())
