extends SubViewportContainer

@export var player : CharacterBody3D
@export var label : Label

@onready var sb: SubViewport = $SubViewport
@onready var camera: Camera3D = $SubViewport/Camera3D

var player_id = 1

func _enter_tree() -> void:
	set_multiplayer_authority(player.name.to_int())
	player_id = player.name.to_int()

func _ready() -> void:
	if Settings.resolution_scale:
		sb.scaling_3d_scale = Settings.resolution_scale

func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	var is_dead = player.is_dead
	get_parent().visible = is_dead and player.parent.can_escape
	if is_dead:
		sb.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		var spectate_target = null
		
		for pl in get_tree().get_nodes_in_group("player"):
			if !pl.is_dead and pl.name != player.name:
				spectate_target = pl
				break
		
		if spectate_target:
			label.text = "Spectating " + spectate_target.steam_name
			camera.global_position = spectate_target.global_position + Vector3(0,0.5,0)
			camera.global_rotation = spectate_target.global_rotation
	else:
		sb.render_target_update_mode = SubViewport.UPDATE_DISABLED
